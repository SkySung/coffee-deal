import requests
from bs4 import BeautifulSoup
import re
import sqlite3

# URL of the webpage you want to scrape
url = "https://www.starbucks.com.tw/stores/allevent.jspx?type=all"
url_prefix = "https://www.starbucks.com.tw/stores/"
db = sqlite3.connect("database.db")
cursor = db.cursor()


def main():
    # Fetch the latest event from starbucks official site
    sub_urls = retrieve_sub_urls()
    if not sub_urls:
        print("No sub URLs found. App Stop")
        return
    
    # Retrieve the latest data from the database
    cursor.execute("SELECT feed_id FROM starbucks ORDER BY feed_id DESC LIMIT 1")
    result = cursor.fetchone()
    latest_feed_id = int(result[0]) if result else 0
    
    # Check if the latest event from site not in the database, if so, save it into the database.
    for sub_url in sub_urls:
        feed_id = re.search(r'\d+$', sub_url)
        if feed_id and int(feed_id.group()) > latest_feed_id:
            data = retrieve_data(sub_url)
            if data:
                save_data(data)
    # If there is new data fetch from site, send to LLM to do reasoning process.
    


def retrieve_data(sub_url):
    data = {"title": "", "date": "", "content": "", "note": ""}
    response = requests.get(url_prefix + sub_url)
    response.encoding = 'utf-8'
    soup = BeautifulSoup(response.content, "html.parser")

    if response.status_code == 200:
        content_div = soup.find("div", class_="content")
        if content_div:
            data["title"] = content_div.find("h3").text.strip() if content_div.find("h3") else ""
            data["date"] = content_div.find("p", class_="marketing_date").text.strip() if content_div.find("p", class_="marketing_date") else ""
            data["content"] = content_div.find("p", class_="event_content").text.strip() if content_div.find("p", class_="event_content") else ""
            data["note"] = content_div.find("p", class_="event_note").text.strip() if content_div.find("p", class_="event_note") else ""
        else:
            print("Content div not found.")
    else:
        print(f"Failed to retrieve the webpage. Status code: {response.status_code}")
        return None

    return data


def retrieve_sub_urls():
    response = requests.get(url)
    sub_urls = []

    # Check if the request was successful
    if response.status_code == 200:
        # Parse the HTML content of the webpage
        soup = BeautifulSoup(response.content, "html.parser")

        # Find the div with id "tabs-1"
        div_tabs = soup.find("div", id="tabs-1")

        if div_tabs:
            li_elements = div_tabs.find_all("li")
            for li in li_elements:
                # Find the a element within the li
                a_tag = li.find("a")
                if a_tag and 'href' in a_tag.attrs:
                    sub_urls.append(a_tag['href'])
        else:
            print("Div with id 'tabs-1' not found.")
    else:
        print(f"Failed to retrieve the webpage. Status code: {response.status_code}")

    return sub_urls


def save_data(data):
    cursor.execute(
        "INSERT INTO starbucks (title, date, content, note) VALUES (?, ?, ?, ?)",
        (data["title"], data["date"], data["content"], data["note"])
    )
    db.commit()


if __name__ == "__main__":
    main()
    db.close()
