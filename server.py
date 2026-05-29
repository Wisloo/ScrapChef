from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase with a service account key
cred = credentials.Credentials.from_service_account_json('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

app = Flask(__name__)

@app.route('/scrap-data', methods=['POST'])
def receive_scrap():
    # Expect JSON payload
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No JSON data'}), 400
    # Store in Firestore collection 'scraps'
    doc_ref = db.collection('scraps').add(data)
    return jsonify({'status': 'ok', 'id': doc_ref[1].id}), 200

if __name__ == '__main__':
    # Listen on all interfaces so ESP32 can reach it
    app.run(host='0.0.0.0', port=3000)
