from flask import Flask, request, jsonify
import whisperx
import torch
import tempfile

app = Flask(__name__)

# device = "cuda" if torch.cuda.is_available() else "cpu"
device = "cpu"  # added
# model = whisperx.load_model("large-v2", device)

model = whisperx.load_model("base", device)  # added

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "no file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "no selected file"}), 400

    if file:
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            file.save(tmp.name)
            audio = whisperx.load_audio(tmp.name)
            with torch.no_grad():  # added
                result = model.transcribe(audio)
                torch.cuda.empty_cache()  # added
            return jsonify(result["segments"]), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
