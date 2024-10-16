from flask import Flask, request, render_template_string, send_file
import pandas as pd
import os

# Path to the directory containing CSV files
csv_directory = 'D:/20240222数据库/TE_utf8'

# Load the default CSV file
df = pd.read_csv(os.path.join(csv_directory, 'Cenchrus_purpureus_purple.TE.csv'), encoding='utf-8')

# Initialize the Flask app
app = Flask(__name__)

# HTML template for the web page
html_template = '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>TE Search</title>
    <link rel="stylesheet" href="https://cdn.datatables.net/1.10.25/css/jquery.dataTables.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.js"></script>
    <script src="https://cdn.datatables.net/1.10.25/js/jquery.dataTables.min.js"></script>
    <style>
      .dataTables_wrapper {
        overflow-x: auto;
      }
      table {
        width: 100%;
        table-layout: auto;
        word-wrap: break-word;
      }
    </style>
    <script>
      $(document).ready(function() {$('#teInformationTable').DataTable({
          "pageLength": 10,
          "paging": true,
          "lengthMenu": [10, 20, 50],
          "processing": true,
          "deferRender": true,
          "retrieve": true
        });
      });
    </script>
  </head>
  <body>
    <h1>TE Search</h1>
    <form method="post" action="/">
      Select Species: 
      <select name="species">
        <option value="Cenchrus_purpureus_purple.TE.csv" {% if species == 'Cenchrus_purpureus_purple.TE.csv' %}selected{% endif %}>Cenchrus purpureus purple</option>
        <option value="Cenchrus_purpureus.TE.csv" {% if species == 'Cenchrus_purpureus.TE.csv' %}selected{% endif %}>Cenchrus purpureus</option>
        <option value="Cenchrus_fungigraminus.TE.csv" {% if species == 'Cenchrus_fungigraminus.TE.csv' %}selected{% endif %}>Cenchrus fungigraminus</option>
        <option value="Miscanthus_lutarioriparius.TE.csv" {% if species == 'Miscanthus_lutarioriparius.TE.csv' %}selected{% endif %}>Miscanthus lutarioriparius</option>
        <option value="Miscanthus_sinensis.TE.csv" {% if species == 'Miscanthus_sinensis.TE.csv' %}selected{% endif %}>Miscanthus sinensis</option>
        <option value="Setaria_viridis.TE.csv" {% if species == 'Setaria_viridis.TE.csv' %}selected{% endif %}>Setaria viridis</option>
      </select>
      <br><br>
      Region (e.g., 57000-57250): <input type="text" name="start" value="{{ region_value }}">
      TE Family (e.g., CACTA): <input type="text" name="family" value="{{ family_value }}">
      <input type="submit" value="Search">
    </form>
    
    {% if results is not none and results|length > 0 %}
      <h2>TE Information:</h2>
      <div class="dataTables_wrapper">
        <table id="teInformationTable" class="display">
          <thead>
            <tr>
              <th>chr</th>
              <th>start</th>
              <th>end</th>
              <th>information</th>
              <th>phase</th>
              <th>strand</th>
              <th>TE family</th>
            </tr>
          </thead>
          <tbody>
          {% for row in results %}
          <tr>
            <td>{{ row.chr }}</td>
            <td>{{ row.start }}</td>
            <td>{{ row.end }}</td>
            <td>{{ row.information }}</td>
            <td>{{ row.phase }}</td>
            <td>{{ row.strand }}</td>
            <td>{{ row['TE family'] }}</td>
          </tr>
          {% endfor %}
          </tbody>
        </table>
      </div>
      <form method="post" action="/download">
      <input type="submit" value="Download Search Results" {% if results is none or results|length == 0 %}disabled{% endif %}>
    </form>{% elif results is not none %}
      <p>No results found.</p>
    {% endif %}
    <br>
    
  </body>
</html>
'''

# Route to handle the search page
@app.route('/download', methods=['POST'])
def download():
    if 'results' in globals() and results:
        download_df = pd.DataFrame(results)
        csv_path = os.path.join(csv_directory, 'search_results.csv')
        download_df.to_csv(csv_path, index=False, encoding='utf-8')
        return send_file(csv_path, as_attachment=True)
    else:
        return "No results to download."

@app.route('/', methods=['GET', 'POST'])
def search():
    global df
    results = None
    region_value = ''
    family_value = ''
    
    if request.method == 'POST':
        species_file = request.form.get('species', 'Cenchrus_purpureus_purple.TE.csv')
        region_value = request.form.get('start', '')
        family_value = request.form.get('family', '').strip()
    else:
        species_file = 'Cenchrus_purpureus_purple.TE.csv'
    
    # Load the selected species CSV file
    df = pd.read_csv(os.path.join(csv_directory, species_file), encoding='utf-8')
    
    if request.method == 'POST':
        filtered_df = df
        try:
            # Handle range input like '57000-57250'
            if region_value:
                if '-' in region_value:
                    start_range, end_range = map(int, region_value.split('-'))
                    filtered_df = filtered_df[(filtered_df['start'] >= start_range) & (filtered_df['end'] <= end_range)]
                else:
                    region_value = int(region_value)
                    filtered_df = filtered_df[(filtered_df['start'] <= region_value) & (filtered_df['end'] >= region_value)]
            # Filter by family if provided
            if family_value:
                filtered_df = filtered_df[filtered_df['TE family'].str.contains(family_value, case=False, na=False)]
            results = filtered_df.head(100).to_dict(orient='records')
        except ValueError:
            results = []
    
    return render_template_string(html_template, results=results, full_data=df, species=species_file, region_value=region_value, family_value=family_value)

# Run the Flask app
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)