from flask import Flask, request, jsonify
import os
import easyocr

UPLOAD_FOLDER = './uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

reader = easyocr.Reader(['en'])  # Add other languages as needed

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/')
def index():
    return "OCR Server Running", 200

@app.route('/favicon.ico')
def favicon():
    return '', 204

@app.route('/upload', methods=['POST'])
def upload():
    print("test here")
    files = request.files.getlist('images')
    results = []

    for i, file in enumerate(files):
        filename = f'image_{i}.jpg'
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        # Perform OCR
        ocr_result = reader.readtext(filepath, detail=0)  # detail=0 returns plain text
        print(filename)
        results.append({
            'filename': filename,
            'text': ocr_result
        })

    return jsonify({'status': 'success', 'results': results})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)