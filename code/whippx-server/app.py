from flask import Flask, request, jsonify
import whisperx
import torch
import tempfile
import time
import threading

app = Flask(__name__)

device = "cuda" if torch.cuda.is_available() else "cpu"
model = whisperx.load_model("large-v2", device, compute_type="float32")
transcriptions = {}

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

@app.route('/send-to-transcribe', methods=['POST'])
def send_to_transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "no file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "no selected file"}), 400

    if file:
        file_id = str(time.time())
        transcriptions[file_id] = {"status": "processing"}

        def transcribe_file(file_content, file_id):
            with tempfile.NamedTemporaryFile(delete=False) as tmp:
                tmp.write(file_content)
                tmp_path = tmp.name

            audio = whisperx.load_audio(tmp_path)
            result = model.transcribe(audio, batch_size=16)
            transcription_text = "\n".join([segment['text'] for segment in result["segments"]])
            transcriptions[file_id] = {"status": "completed", "transcription": transcription_text}

        file_content = file.read()
        threading.Thread(target=transcribe_file, args=(file_content, file_id)).start()

        return jsonify({"file_id": file_id}), 200

@app.route('/get-response', methods=['GET'])
def get_response():
    file_id = request.args.get('file_id')
    if file_id not in transcriptions:
        return jsonify({"error": "file not found"}), 404

    if transcriptions[file_id]["status"] == "completed":
        return transcriptions[file_id]["transcription"], 200

    if transcriptions[file_id]["status"] == "processing":
        return jsonify({"status": "processing"}), 404
    
    else:
        return jsonify({"error": "unknown error"}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
