from flask import Flask, request, jsonify
import whisperx
import torch

app = Flask(__name__)

device = "cuda" if torch.cuda.is_available() else "cpu"
model = whisperx.load_model("large-v2", device)

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "no file part"})
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "no selected file"})
    
    if file:
        audio = whisperx.load_audio(file)
        result = model.transcribe(audio)
        return jsonify(result["segments"])

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
