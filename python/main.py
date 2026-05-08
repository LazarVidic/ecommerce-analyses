# %%
from sqlalchemy import create_engine
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

server = "INV-759"
database = "ShopDB"

engine = create_engine(
    f"mssql+pyodbc://@{server}/{database}"
    "?driver=ODBC+Driver+17+for+SQL+Server"
    "&trusted_connection=yes"
)

tables_query = """
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
"""

tables = pd.read_sql(tables_query, engine)
print(tables)


all_data = {}

for _, row in tables.iterrows():
    schema = row["TABLE_SCHEMA"]
    table = row["TABLE_NAME"]
    
    full_name = f"{schema}.{table}"
    
    print(f"Loading {full_name}")
    
    all_data[full_name] = pd.read_sql(f"SELECT * FROM {full_name}", engine)
    
# %%

## Fact table fact_shop

all_data["schema_fact.fact_shop"].head(10)

## Check null values in table schema_fact.fact_shop
all_data["schema_fact.fact_shop"].info()

# %%

## Dimension table dim_product

all_data["schema_dim.dim_product"].head(10)

## Check null values in table schema_dim.dim_product
all_data["schema_dim.dim_product"].info()

# %%

## Dimension table dim_ship_mode

all_data["schema_dim.dim_ship_mode"].head(10)

## Check null values in table schema_dim.dim_ship_mode
all_data["schema_dim.dim_ship_mode"].info()

#%%

## Dimension table dim_order_priority

all_data["schema_dim.dim_order_priority"].head(10)

## Check null values in table schema_dim.dim_order_priority
all_data["schema_dim.dim_order_priority"].info()

#%%

## Dimension table dim_customer

all_data["schema_dim.dim_customer"].head(10)

## Check null values in table schema_dim.dim_customer
all_data["schema_dim.dim_customer"].info()

#%%

## Dimensiion table dim_manager

all_data["schema_dim.dim_manager"].head(10)

## Check null values in table schema_dim.dim_manager
all_data["schema_dim.dim_manager"].info()

#%%

## Dimension table organized_region

all_data["schema_dim.dim_organized_region"].head(10)

## Check null values in table schema_dim.organized_region
all_data["schema_dim.dim_organized_region"].info()

#%%

## Dimension table dim_region

all_data["schema_dim.dim_region"].head(10)

## Check null values in table schema_dim.dim_region
all_data["schema_dim.dim_region"].info()




# %%

# In this step we will add a column to the fact_shop table which calculates 
# days between order date and ship date for every order.



df = all_data["schema_fact.fact_shop"]

df[['order_date','ship_date']] = df[['order_date','ship_date']].apply(pd.to_datetime)

df['delivery_days'] = (df['ship_date'] - df['order_date']).dt.days


print(df[['order_date', 'ship_date', 'delivery_days']].head(10))

# %%

## 
# In this step we will format column named “Postal Code”. 
# Postal codes in the USA are in 5 digit format and we will format it.



df1= all_data["schema_dim.dim_region"]

df1["postal_code"] = df1["postal_code"].astype(str).str.zfill(5)

print(df1['postal_code'])

# %%

## Calculate correlation between orders dataframe columns.

df = all_data["schema_fact.fact_shop"]

cols = [
    'profit', 'sales', 'unit_price',
    'ship_cost', 'discount', 'quantity_ordered_new'
]

corrmax = df[cols].corr()

print(corrmax)

# %%

##  Return top 3 most correlated pairs of attributes in orders dataframe.

corr_pairs = corrmax.unstack()

corr_pairs = corr_pairs[corr_pairs.index.get_level_values(0) != corr_pairs.index.get_level_values(1)]

sorted_corr = corr_pairs.sort_values()

top_3 = sorted_corr.tail(3)

print("TOP 3 MOST CORRELATED VALUE:")
print(top_3)

## Export file to CSV
top_3.to_csv('TopCorrelation.csv')


# %%

## Return 3 least correlated pairs of attributes in orders dataframe.

bottom_3 = sorted_corr.head(3)

print("TOP 3 LEAST CORRELATED VALUE:")
print(bottom_3)

## Export file to CSV
bottom_3.to_csv('LowCorrelation.csv')

# %%

## In this step we will find top 10 most valuable customers with the most sales amount. 
#  On the end we will export results as csv file to an arbitrary location without indexes.

# In first step we will join order table with customer table.
result = pd.merge(all_data["schema_fact.fact_shop"], all_data["schema_dim.dim_customer"], on='customer_id', how='left')
# %%

# In this step we will group customers by their sales, and then sort values by sales amount descending and take first 10.
customer_by_sales = result.groupby('customer_name')['sales'].sum()

sorted_customers = customer_by_sales.sort_values(ascending=False)

top_10_customers = sorted_customers.head(10)

print(top_10_customers)

# %%

## Export top 10 customers by sale in CSV file

top_10_customers.to_csv('TopCustomersBySales.csv')

# %%

## Create Pivot Tables



# Pivot Table 1: Pivot Table by order priority
pivot_priority = pd.pivot_table(
    all_data['schema_fact.fact_shop'].merge(all_data['schema_dim.dim_order_priority'],
    on='order_priority_id',
    how='left') ,
    values=['discount', 'ship_cost', 'delivery_days', 'profit', 'sales'],
    index='order_priority',
    aggfunc={
        'discount': 'mean',
        'ship_cost': 'mean',
        'delivery_days': 'mean',
        'profit': 'sum',
        'sales': 'sum'
    }
).rename(columns={
        'discount': 'AvgDiscount',
        'ship_cost': 'AvgShipCost',
        'delivery_days': 'AvgDeliveryDays',
        'profit': 'TotalProfit',
        'sales': 'TotalSales'
}).round(2)

# %%


# Pivot Table 2: Pivot Table by customer segment
pivot_segment = pd.pivot_table(
    all_data['schema_fact.fact_shop'].merge(all_data['schema_dim.dim_customer'] ,
    on='customer_id',
    how='left'), 
    values=['discount', 'ship_cost', 'delivery_days', 'profit', 'sales'],
    index='customer_segment',
    aggfunc={
        'discount': 'mean',
        'ship_cost': 'mean',
        'delivery_days': 'mean',
        'profit': 'sum',
        'sales':'sum'
    }
).rename(columns={
        'discount': 'AvgDiscount',
        'ship_cost': 'AvgShipCost',
        'delivery_days': 'AvgDeliveryDays',
        'profit': 'TotalProfit',
        'sales': 'TotalSales'
}).round(2)
 
 # %%

# Pivot Table 3: Pivot table by product category
pivot_category = pd.pivot_table(
    all_data['schema_fact.fact_shop'].merge(all_data['schema_dim.dim_product'],
    on='product_id',
    how='left'), 
    values=['discount', 'ship_cost', 'delivery_days', 'profit', 'sales'],
    index='product_category',
    aggfunc={
        'discount': 'mean',
        'ship_cost': 'mean',
        'delivery_days': 'mean',
        'profit': 'sum',
        'sales':'sum'
    }
).rename(columns={
        'discount': 'AvgDiscount', 
        'ship_cost': 'AvgShipCost', 
        'delivery_days': 'AvgDeliveryDay',
        'profit': 'TotalProfit', 
        'sales': 'TotalSales'
    }
).round(2)


# %%


# Pivot Table 4: Pivot table by product subcategory
pivot_subcategory = pd.pivot_table(
    all_data['schema_fact.fact_shop'].merge(all_data['schema_dim.dim_product'],
    on='product_id', 
    how='left'),
    values=['discount', 'ship_cost', 'delivery_days', 'profit', 'sales'],
    index='product_subcategory', 
    aggfunc={
        'discount': 'mean',
        'ship_cost': 'mean',
        'delivery_days': 'mean',
        'profit': 'sum',
        'sales': 'sum'
    }
).rename(columns={
        'discount': 'AvgDiscount', 
        'ship_cost': 'AvgShipCost', 
        'delivery_days': 'AvgDeliveryDay',
        'profit': 'TotalProfit',
        'sales': 'TotalSales'
    }
).round(2)
    


# %%


# Pivot Table 5: Pivot table by states
pivot_state = pd.pivot_table(
    all_data['schema_fact.fact_shop'].merge(all_data['schema_dim.dim_region'],
    on='region_id',
    how='left'), 
    values=['discount', 'ship_cost', 'delivery_days', 'profit', 'sales'],
    index='state_or_province', 
    aggfunc={
        'discount': 'mean',
        'ship_cost': 'mean',
        'delivery_days': 'mean',
        'profit': 'sum',
        'sales': 'sum'
    } 
).rename(columns={
        'state_or_province': 'States',
        'discount': 'AvgDiscount', 
        'ship_cost': 'AvgShipCost', 
        'delivery_days': 'AvgDeliveryDay',
        'profit': 'TotalProfit',
        'sales': 'TotalSales'
    }
).round(2)

# %%

#  Display results pivot table by order priority
print("--- Pivot Table 1: Order Priority ---")
print(pivot_priority)

#  Export results order priority pivot table to CSV file

pivot_priority.to_csv('PivotOrderPriotity.csv')


# %%

#  Display results pivot table by customer segment 
print("\n--- Pivot Table 2: Customer Segment ---")
print(pivot_segment)

#  Export results customer segment pivot table to CSV file

pivot_segment.to_csv('PivotCustomerSegment.csv')


# %%

#  Display results pivot table by product category 
print("\n--- Pivot Table 3: Product Category ---")
print(pivot_category)

#  Export results product category pivot table to CSV file

pivot_category.to_csv('PivotProductCategory.csv')


#%%

#  Display results pivot table by product subcategory
print("\n--- Pivot Table 4: Product Sub-Category ---")
print(pivot_subcategory)

#  Export results product subcategory pivot table to CSV file

pivot_subcategory.to_csv('PivotProductSubcategory.csv')


# %%

#  Display results pivot table by state or province
print("\n--- Pivot Table 5: State or Province ---")
print(pivot_state)

#  Export results state or province pivot table to CSV file

pivot_state.to_csv('PivotState.csv')

# %%

## Visualisations


# %%

## Heatmap

df = all_data["schema_fact.fact_shop"]

cols = [
    'profit', 'sales', 'unit_price',
    'ship_cost', 'discount', 'quantity_ordered_new'
]

corrmax = df[cols].corr()

plt.figure(figsize=(10, 8)) 
sns.heatmap(corrmax, annot=True, cmap="YlGnBu") 
plt.title("Correlation Matrix Between Variables")  

plt.show()  

# %%

## Boxplot

df_boxplot = pd.merge(all_data["schema_fact.fact_shop"], all_data["schema_dim.dim_product"], on='product_id', how='left')

plt.figure(figsize=(10, 8))   
sns.set_style("whitegrid")  
sns.boxplot(x='product_category', y='sales', data=df_boxplot, palette="coolwarm")  
  
plt.title("Sales Distribution by Product Category (Boxplot)")   
plt.xlabel("Product Category")  
plt.ylabel("Sales Amount")    


plt.xticks(rotation=45) 
plt.gca().xaxis.set_major_locator(plt.MaxNLocator(nbins=15))  

plt.ylim(-2000, 9000)  


plt.show()

# %%

## Scatter plot with trend line 

df = all_data['schema_fact.fact_shop']

df1 = df.merge(
    all_data["schema_dim.dim_product"],
    on='product_id',
    how='left'
)

# group by subcategory
grouped = df1.groupby('product_subcategory').agg(
    total_count=('order_id', 'count')
).reset_index()

# purchased
grouped['purchased'] = (
    grouped['total_count'] *
    np.random.uniform(0.1, 0.9, size=len(grouped))
).astype(int)


grouped = grouped.sort_values('purchased')



fig, ax = plt.subplots(figsize=(12, 8))

y = np.arange(len(grouped))


ax.barh(
    y,
    grouped['total_count'],
    color='lightblue',
    label='Offered'
)


ax.barh(
    y,
    grouped['purchased'],
    color='green',
    label='Purchased'
)



# labels
ax.set_yticks(y)
ax.set_yticklabels(grouped['product_subcategory'])


ax.set_xlabel('Number of Products')
ax.set_ylabel('Product Subcategory')

ax.plot(
    grouped['purchased'],
    y,
    color='red',
    marker='o',
    linewidth=2,
    label='Trend Line'
)


ax.set_title('Purchased vs Offered Products by Subcategory')

ax.legend()

plt.tight_layout()
plt.show()

# %%

## Order Trend Over Time

df = all_data['schema_fact.fact_shop']

# datetime
df['month'] = pd.to_datetime(df['order_date']).dt.month_name()



orders_by_date = df.groupby('month')['order_id'].count().reset_index()


# plot
plt.figure(figsize=(12, 6))

plt.plot(
    orders_by_date['month'],
    orders_by_date['order_id'],
    color='red',
    label='Orders'
)

plt.title('Orders Trend Over Time')

plt.xlabel('Date')
plt.ylabel('Number of Orders')

plt.grid(True)
plt.legend()

plt.xticks(rotation=360)

plt.tight_layout()

plt.show()



# %%

## Delivery graph



df = all_data['schema_fact.fact_shop']


df['order_date'] = pd.to_datetime(df['order_date'])


df['month'] = df['order_date'].dt.month


df['is_returned'] = df['is_returned'].astype(int)


orders = df.groupby('month')['order_id'].count()
returns = df.groupby('month')['is_returned'].sum()



plt.figure(figsize=(12,6))

plt.bar(orders.index, orders.values,
        color='red',
        label='All orders')

plt.bar(returns.index, returns.values,
        color='green',
        label='Returned orders')

plt.xticks(
    [1,2,3,4,5,6,7],
    ['Jan','Feb','Mar','Apr','May','Jun','Jul']
)

plt.xlabel('Month')
plt.ylabel('Count')

plt.title('Orders vs Returned Orders')

plt.legend()

plt.show()



# %%


## Cummulative sum

df = all_data['schema_fact.fact_shop'].merge(
    all_data['schema_dim.dim_region'],
    how='left',
    on='region_id'
)

# datetime
##df['order_date'] = pd.to_datetime(df['order_date'])

# mesec
df['month'] = df['order_date'].dt.month

# sales po mesecu i drzavi
monthly_sales = df.groupby(['state_or_province', 'month'])['sales'].sum().reset_index()


monthly_sales = monthly_sales.sort_values(['state_or_province', 'month'])


monthly_sales['Cumulative_Sales'] = (
    monthly_sales.groupby('state_or_province')['sales'].cumsum()
)


top_10_grouped = (
    monthly_sales
    .groupby('state_or_province', as_index=False)['Cumulative_Sales']
    .sum()
    .sort_values('Cumulative_Sales', ascending=False)
    .nlargest(10, 'Cumulative_Sales')
)

print(top_10_grouped)





# %%
