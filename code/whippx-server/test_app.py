import unittest
import base64
from unittest.mock import patch, MagicMock
from app import app, socketio
import json

class TestSocketIO(unittest.TestCase):
    def setUp(self):
        self.client = socketio.test_client(app)
        self.client.connect()

    def tearDown(self):
        self.client.disconnect()

    @patch('app.whisperx.load_audio')
    @patch('app.get_model')
    def test_transcribe_success(self, mock_get_model, mock_load_audio):
        # Mock the model and its transcribe method
        mock_model = MagicMock()
        mock_model.transcribe.return_value = {"segments": [{"text": "hello world"}]}
        mock_get_model.return_value = mock_model
        mock_load_audio.return_value = "mock_audio_data"

        # Create a dummy audio file (just some bytes)
        dummy_audio_data = b'RIFF....WAVEfmt '

        # Emit the transcribe event
        self.client.emit('transcribe', {
            'audio': base64.b64encode(dummy_audio_data).decode('utf-8'),
            'model_size': 'small'
        })

        # Get the received events
        received = self.client.get_received()

        # Check that we received the transcription result
        self.assertEqual(len(received), 1)
        self.assertEqual(received[0]['name'], 'transcription_result')
        data = received[0]['args'][0]
        self.assertEqual(data['transcription'], 'hello world')

    def test_invalid_model_size(self):
         # Create a dummy audio file
        dummy_audio_data = b'RIFF....WAVEfmt '

        self.client.emit('transcribe', {
            'audio': base64.b64encode(dummy_audio_data).decode('utf-8'),
            'model_size': 'invalid_model'
        })

        received = self.client.get_received()
        self.assertEqual(len(received), 1)
        self.assertEqual(received[0]['name'], 'error')
        self.assertEqual(received[0]['args'][0]['error'], 'Invalid model size')

if __name__ == '__main__':
    unittest.main()
