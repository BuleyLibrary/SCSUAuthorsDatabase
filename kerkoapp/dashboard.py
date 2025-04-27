from flask import Blueprint, render_template, current_app
import re
import json
from whoosh.index import open_dir
from collections import defaultdict


dashboard_bp = Blueprint('main', __name__)


def string_to_dict(input_str):
    # Split the string by commas to separate key-value pairs
    # Regular expression to match the first colon after a key (not in a URL)
    pattern = r"([^:]+):\s*([^,]+(?:https?://[^\s,]+)?)\s*(?:,|\s*$)"
    
    # Find all matches
    matches = re.findall(pattern, input_str)
    
    # Convert matches to a dictionary
    result_dict = {key.strip(): value.strip() for key, value in matches}

    if 'Citation Key Alias' in result_dict:
        value = result_dict['Citation Key Alias']
        result = value.split('\n')[0]
        result_dict = {'lenslink' : result}

    return result_dict

def get_whoosh_items():
    # Path to the Whoosh index directory
    index_dir = current_app.config.get("WHOOSH_INDEX_DIR", "instance/kerko/cache/whoosh")
    
    # Open the Whoosh index
    ix = open_dir(index_dir)
    
    # Retrieve all items from the Whoosh index
    items = []
    with ix.searcher() as searcher:
        for fields in searcher.all_stored_fields():
            items.append(fields)
            # Sort items by date (most recent first) and get top 5
    items = sorted(items, key=lambda x: x['data'].get('dateAdded', ''), reverse=True)

    return items

def process_for_dashboard(items):
     # Process Zotero items
        processed = []
        for item in items:
            # Extract data from Zotero's nested structure
            data = item.get('data', {})
            newdata = []
            
            # Get creators from data
            creators = []
            for creator in data.get('creators', []):
                creators.append({
                    'name': f"{creator.get('firstName', '')} {creator.get('lastName', '')}".strip()
                })
            newdata.append({'creators': creators})
      
            
            # Get citations Data (stored in "extra")
            extra_str = data.get('extra', '')
            extra_dict = string_to_dict(extra_str)
            newdata.append({'extra' : extra_dict})

            newdata.append ({
                'title' : data.get('title', ''),
                'date' : data.get('date', ''),
                'DOI' : data.get('DOI', ''),
                'url' : data.get('url', '')
            })
            processed.append(newdata)
        return processed

# Extract and sort items by 'CitedBy' value
def get_cited_by(item):
    # Safely extract the 'CitedBy' value, defaulting to 0 if not present
    extra = next((field['extra'] for field in item if 'extra' in field), {})
    return int(extra.get('CitedBy', 0))

def get_work_counts_per_year_whoosh(items):
    year_counts = defaultdict(int)
    
    # Search for all items
    for item in items:
        data = item.get("data", {})
        if isinstance(data, dict):
            date = data.get("date", "")
            year = date[:4]
            if year.isdigit() and int(year) >= 2012:
                year_counts[year] += 1

    # Print or return results
    for year in sorted(year_counts):
        print(f"{year}: {year_counts[year]}")
    return year_counts

def get_item_type_counts(items):
    item_type_counts = defaultdict(int)
    
    # Count occurrences of each itemType
    for item in items:
        data = item.get("data", {})
        if isinstance(data, dict):
            item_type = data.get("itemType", "Unknown")
            item_type_counts[item_type] += 1

    return item_type_counts

@dashboard_bp.route('/dashboard')
def index():
    try:
        # Get items from Whoosh index
        items = get_whoosh_items()

        # Process items for dashboard tile
        zotero_items = process_for_dashboard(items)

        # Sort items by 'CitedBy' in descending order
        sorted_items = sorted(zotero_items, key=get_cited_by, reverse=True)

        # Take the top 5 items
        all_data = sorted_items[:5]
        
        # Handle empty data
        if not all_data:
            all_data = [{
                'title': 'No Items Found',
                'creators': [],
                'abstractNote': 'Please check your Zotero library and API credentials.',
                'stats': {
                    'total_citations': 0,
                    'recent_views': 0,
                    'author_count': 0
                }
            }]
        
        # Get entries per year data from Whoosh index items
        year_data = get_work_counts_per_year_whoosh(items)
        years = sorted(year_data.keys())
        counts = [year_data[year] for year in years]

        # Generate bar chart data
        chart_data = {
            'type': 'bar',
            'data': {
                'labels': years,
                'datasets': [{
                    'label': 'Publications per Year',
                    'data': counts,
                    'backgroundColor': 'rgba(0, 123, 255, 0.5)',
                    'borderColor': 'rgba(0, 123, 255, 1)',
                    'borderWidth': 1
                }]
            },
            'options': {
                'responsive': True,
                'scales': {
                    'yAxes': [{
                        'ticks': {
                            'beginAtZero': True
                        }
                    }]
                }
            }
        }

        # Get item type counts for pie chart
        item_type_data = get_item_type_counts(items)
        item_types = list(item_type_data.keys())
        item_counts = list(item_type_data.values())

        # Generate pie chart data
        pie_chart_data = {
            'type': 'pie',
            'data': {
                'labels': item_types,
                'datasets': [{
                    'data': item_counts,
                    'backgroundColor': [
                        'rgba(255, 99, 132, 0.5)',
                        'rgba(54, 162, 235, 0.5)',
                        'rgba(255, 206, 86, 0.5)',
                        'rgba(75, 192, 192, 0.5)',
                        'rgba(153, 102, 255, 0.5)',
                        'rgba(255, 159, 64, 0.5)',
                        'rgba(201, 203, 207, 0.5)',
                        'rgba(255, 87, 51, 0.5)',
                        'rgba(60, 179, 113, 0.5)',
                        'rgba(123, 104, 238, 0.5)',
                        'rgba(255, 140, 0, 0.5)',
                        'rgba(0, 191, 255, 0.5)',
                        'rgba(220, 20, 60, 0.5)',
                        'rgba(34, 139, 34, 0.5)',
                        'rgba(255, 215, 0, 0.5)',
                        'rgba(70, 130, 180, 0.5)',
                        'rgba(199, 21, 133, 0.5)',
                        'rgba(244, 164, 96, 0.5)'
                    ],
                    'borderColor': [
                        'rgba(255, 99, 132, 1)',
                        'rgba(54, 162, 235, 1)',
                        'rgba(255, 206, 86, 1)',
                        'rgba(75, 192, 192, 1)',
                        'rgba(153, 102, 255, 1)',
                        'rgba(255, 159, 64, 1)',
                        'rgba(201, 203, 207, 1)',
                        'rgba(255, 87, 51, 1)',
                        'rgba(60, 179, 113, 1)',
                        'rgba(123, 104, 238, 1)',
                        'rgba(255, 140, 0, 1)',
                        'rgba(0, 191, 255, 1)',
                        'rgba(220, 20, 60, 1)',
                        'rgba(34, 139, 34, 1)',
                        'rgba(255, 215, 0, 1)',
                        'rgba(70, 130, 180, 1)',
                        'rgba(199, 21, 133, 1)',
                        'rgba(244, 164, 96, 1)'
                    ],
                    'borderWidth': 1
                }]
            },
            'options': {
                'responsive': True
            }
        }

        return render_template("dashboard.html.jinja2", 
                             all_data=all_data,
                             chartJSON=json.dumps(chart_data),
                             pieChartJSON=json.dumps(pie_chart_data),
                             rss_feed_url=(current_app.config['SERVER_NAME'] or 'http://localhost') + '/feed.rss')
        
    except Exception as e:
        all_data = [{
            'title': 'Error Loading Items',
            'creators': [],
            'abstractNote': f'An error occurred: {str(e)}. Please check your Zotero API credentials.',
            'stats': {
                'total_citations': 0,
                'recent_views': 0,
                'author_count': 0
            }
        }]
        return render_template("dashboard.html.jinja2", 
                             all_data=all_data,
                             rss_feed_url=(current_app.config['SERVER_NAME'] or 'http://localhost') + '/feed.rss')

