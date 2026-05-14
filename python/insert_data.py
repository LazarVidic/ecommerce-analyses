from sqlalchemy import create_engine, text
import pandas as pd

SERVER_NAME   = r"INV-759"
DATABASE_NAME = "ShopDB"
FILE_PATH = r"C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\sales_jun_july.csv"

def connect_to_db():
    conn_string = (
        f"mssql+pyodbc://{SERVER_NAME}/{DATABASE_NAME}"
        "?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes"
    )
    return create_engine(conn_string, fast_executemany=True)

def extract_data(file_path):
    df = pd.read_csv(file_path, sep="|")
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
        .str.replace("-", "_")
        .str.replace(",", "")  
    )

    df["order_id"] = df["order_id"].astype(str).str.replace(",", "").str.strip()

    df = df.rename(columns={
        "customer_id": "customer_key",
        "product_sub_category": "product_subcategory",
        "shipping_cost": "ship_cost",
    })
    df["postal_code"] = pd.to_numeric(df["postal_code"], errors="coerce").astype("Int64")
    df["order_date"]  = pd.to_datetime(df["order_date"],  errors="coerce")
    df["ship_date"]   = pd.to_datetime(df["ship_date"],   errors="coerce")
    print("Columns:", df.columns.tolist())
    return df

def create_dimensions(df):
    dim_customer = df[
        ["customer_key", "customer_name", "customer_segment"]
    ].drop_duplicates(subset=["customer_key"])

    dim_product = df[
        ["product_category", "product_subcategory", "product_container", 
         "product_name", "product_base_margin"]
    ].drop_duplicates(subset=["product_name"])

    dim_region = df[
        ["country", "region", "state_or_province", "postal_code"]
    ].drop_duplicates()

    dim_ship_mode      = df[["ship_mode"]].drop_duplicates()
    dim_order_priority = df[["order_priority"]].drop_duplicates()

    dim_organized_region = df[["region"]].drop_duplicates().rename(columns={"region": "org_region"})

    all_dates = pd.concat([df["order_date"], df["ship_date"]]) \
                  .dropna().drop_duplicates() \
                  .rename("date").to_frame()

    return {
        "dim_customer":       dim_customer,
        "dim_product":        dim_product,
        "dim_region":         dim_region,
        "dim_ship_mode":      dim_ship_mode,
        "dim_order_priority": dim_order_priority,
        "dim_organized_region": dim_organized_region
    }, all_dates  

def load_dimensions(dims, engine):
    unique_keys = {
        "dim_customer": ["customer_key"],
        "dim_product": ["product_name"],
        "dim_region": ["state_or_province", "postal_code"],
        "dim_ship_mode": ["ship_mode"],
        "dim_order_priority": ["order_priority"],
        "dim_organized_region": ["org_region"],
    }

    with engine.connect() as conn:
        for table_name, df in dims.items():
            keys = unique_keys[table_name]

            existing = pd.read_sql(
                text(f"""
                    SELECT {", ".join(keys)}
                    FROM schema_dim.{table_name}
                """),
                conn
            )

            existing_keys = set(
                existing[keys]
                .fillna("")
                .astype(str)
                .agg("|".join, axis=1)
            )

            new_keys = (
                df[keys]
                .fillna("")
                .astype(str)
                .agg("|".join, axis=1)
            )

            new_rows = df[~new_keys.isin(existing_keys)].copy()

            if new_rows.empty:
                print(f" {table_name}: No new rows")
                continue

            new_rows.to_sql(
                name=table_name,
                schema="schema_dim",
                con=engine,
                if_exists="append",
                index=False,
            )

    print(f" {table_name}: Added {len(new_rows)} new rows")




def load_dim_date(all_dates, engine):
        with engine.connect() as conn:
            existing = pd.read_sql(
                text("SELECT date FROM schema_dim.dim_date"), conn
            )
        existing_dates = set(pd.to_datetime(existing["date"]).dt.date)

        all_dates["date_only"] = pd.to_datetime(all_dates["date"]).dt.date
        new_dates = all_dates[~all_dates["date_only"].isin(existing_dates)][["date"]]

        if new_dates.empty:
            print("✓ dim_date: nema novih datuma")
            return

        new_dates.to_sql(
            name="dim_date", schema="schema_dim",
            con=engine, if_exists="append", index=False,
        )

  
def load_dimension_keys(engine):
    with engine.connect() as conn:
        customer = pd.read_sql(text("""
            SELECT customer_id, customer_key FROM schema_dim.dim_customer
        """), conn)
        product = pd.read_sql(text("""
            SELECT product_id, product_name FROM schema_dim.dim_product
        """), conn)
        region = pd.read_sql(text("""
            SELECT region_id, state_or_province, postal_code FROM schema_dim.dim_region
        """), conn)
        ship_mode = pd.read_sql(text("""
            SELECT ship_mode_id, ship_mode FROM schema_dim.dim_ship_mode
        """), conn)
        priority = pd.read_sql(text("""
            SELECT order_priority_id, order_priority FROM schema_dim.dim_order_priority
        """), conn)
        organized_region = pd.read_sql(text("""
            SELECT organized_region_id, org_region FROM schema_dim.dim_organized_region
        """), conn)
    return {
        "customer":  customer,
        "product":   product,
        "region":    region,
        "ship_mode": ship_mode,
        "priority":  priority,
        "organized_region": organized_region
    }

def build_fact(df, dim_keys):
    customer  = dim_keys["customer"].drop_duplicates(subset=["customer_key"])
    product   = dim_keys["product"].drop_duplicates(subset=["product_name"])
    ship_mode = dim_keys["ship_mode"].drop_duplicates(subset=["ship_mode"])
    priority  = dim_keys["priority"].drop_duplicates(subset=["order_priority"])
    organized_region  = dim_keys["organized_region"].drop_duplicates(subset=["org_region"])
    region    = dim_keys["region"].drop_duplicates(subset=["state_or_province", "postal_code"])

    customer_map = customer.set_index("customer_key")["customer_id"].to_dict()
    df["customer_fk"] = df["customer_key"].map(customer_map)

    product_map = product.set_index("product_name")["product_id"].to_dict()
    df["product_fk"] = df["product_name"].map(product_map)

    region["postal_code"] = region["postal_code"].astype("Int64")
    region_key_db = region["state_or_province"].astype(str) + "|" + region["postal_code"].astype(str)
    region_map = dict(zip(region_key_db, region["region_id"]))
    df["region_fk"] = (
        df["state_or_province"].astype(str) + "|" + df["postal_code"].astype(str)
    ).map(region_map)

    ship_map = ship_mode.set_index("ship_mode")["ship_mode_id"].to_dict()
    df["ship_mode_fk"] = df["ship_mode"].map(ship_map)

    priority_map = priority.set_index("order_priority")["order_priority_id"].to_dict()
    df["order_priority_fk"] = df["order_priority"].map(priority_map)

    organized_region_map = organized_region.set_index("org_region")["organized_region_id"].to_dict()
    df["organized_region_fk"] = df["region"].map(organized_region_map)
    ##print(df.columns)


    fk_cols = ["customer_fk", "product_fk", "region_fk", "ship_mode_fk", "order_priority_fk", "organized_region_fk"]
    print("NULL FK counts:\n", df[fk_cols].isnull().sum())

    bad = df[df[fk_cols].isnull().any(axis=1)]
    if not bad.empty:
        bad.to_csv("unmapped_rows.csv", index=False)
        print(f" {len(bad)} unmapped rows → unmapped_rows.csv")

    fact = df[[
        "order_id", "product_fk", "ship_mode_fk", "order_priority_fk",
        "customer_fk", "region_fk", "profit", "sales", "ship_date", "organized_region_fk",
        "unit_price", "order_date", "ship_cost", "discount", "quantity_ordered_new",
    ]].rename(columns={
        "customer_fk": "customer_id",
        "product_fk": "product_id",
        "region_fk": "region_id",
        "ship_mode_fk": "ship_mode_id",
        "order_priority_fk":"order_priority_id",
        "organized_region_fk": "organized_region_id"
    })

    fact = fact.dropna(subset=["customer_id", "product_id", "region_id",
                                "ship_mode_id", "order_priority_id", "organized_region_id"])
    return fact

def load_fact(fact_df, engine):
        fact_df.to_sql(
            name="fact_shop", schema="schema_fact",
            con=engine, if_exists="append", index=False,
        )


def etl_pipeline():

    engine = connect_to_db()
   
    df = extract_data(FILE_PATH)
    dims, all_dates = create_dimensions(df)
    load_dimensions(dims, engine)
    load_dim_date(all_dates, engine)       
    dim_keys = load_dimension_keys(engine)
    fact_df  = build_fact(df, dim_keys)
    load_fact(fact_df, engine)
   
    print("ETL done.")

if __name__ == "__main__":
    etl_pipeline()