from flask import Flask, request, jsonify
import whisperx
import torch
import tempfile
import time

app = Flask(__name__)

device = "cuda" if torch.cuda.is_available() else "cpu"
model = whisperx.load_model("large-v2", device, compute_type="float32")

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
        start_time = time.time()
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            file.save(tmp.name)
            audio = whisperx.load_audio(tmp.name)
            result = model.transcribe(audio, batch_size=16)
            print(result["segments"])
            print("result line executed")
            transcription_text = "\n".join([segment['text'] for segment in result["segments"]])
            print("transcription_text line executed")
            end_time = time.time()
            total_time = end_time - start_time
            print(f"Total transcription time: {total_time:.2f} seconds")
            return transcription_text, 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
