import time
import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup

# Configure Chrome options
chrome_options = Options()
chrome_options.add_argument("--start-maximized")

# Automatically manage ChromeDriver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

try:
    # Open the target URL
    url = 'https://www.jbhifi.com.au/collections/tvs'  # Change URL for different categories
    driver.get(url)
    time.sleep(5)  # Allow time for the page to load

    # Scroll to load all products
    while True:
        try:
            # Wait for the "Load More" button to become clickable
            load_more_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, 'button.load-more-button'))
            )

            # Click the button to load more products
            driver.execute_script("arguments[0].click();", load_more_button)
            time.sleep(3)  # Wait for the new products to load

        except Exception as e:
            print("No more 'Load More' button found or an error occurred:", e)
            break

    # Get the page source after scrolling
    page_source = driver.page_source

finally:
    driver.quit()

# Parse the page source with BeautifulSoup
soup = BeautifulSoup(page_source, "html.parser")

# Extract product information
products = []
product_elements = soup.select('div[data-testid="product-card-title"]')  # Adjust as necessary for different product listings

# Loop through all identified product elements
for product in product_elements:
    try:
        product_info = {}

        # Extract product name
        product_info['Name'] = product.get_text(strip=True)

        # Extract price
        price_element = product.find_next('span', class_='PriceFont_fontStyle__w0cm2q1 PriceTag_actual__1eb7mu9q PriceTag_actual_variant_small__1eb7mu9s')
        product_info['Price'] = price_element.get_text(strip=True) if price_element else 'N/A'

        # Extract the brand name from the image's alt attribute
        img_element = product.find_previous('img', class_='_10ipotx2r')  # Adjust the class as necessary
        product_info['Brand'] = img_element['alt'] if img_element and 'alt' in img_element.attrs else 'N/A'

        # Extract promo information
        promo_element = product.find_next('span', attrs={'data-testid': 'product-card-promo-tag-0'})
        product_info['Promo'] = promo_element.get_text(strip=True) if promo_element else 'N/A'

        # Extract the number of reviews (if available)
        review_element = product.find_next('div', class_='_6zw1gnb _6zw1gna')
        if review_element:
            # Clean and convert the review count to a positive integer
            review_text = review_element.get_text(strip=True).strip('()')  # Remove parentheses
            product_info['Number of reviews'] = int(review_text) if review_text.isdigit() else 'N/A'
        else:
            product_info['Number of reviews'] = 'N/A'

        # Extract rating (if available)
        rating_element = product.find_next('div', class_='_6zw1gna')
        product_info['Rating'] = rating_element.get_text(strip=True) if rating_element else 'N/A'

        # Check for Free Delivery
        free_delivery_element = product.find_next('span', class_='CalloutFont_fontStyle__1589ec81 PriceTag_footerTagText__1eb7mu91m')
        product_info['Free Delivery'] = 'Yes' if free_delivery_element else 'No'

        products.append(product_info)

    except Exception as e:
        print(f"Error extracting product data: {e}")

# Create a DataFrame
df = pd.DataFrame(products)

# Save to a CSV file
df.to_csv('jbhifi_products_data.csv', index=False)
print("Data extracted and saved to jbhifi_products_data.csv.")
print(df)
