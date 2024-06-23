# app.py
from flask import Flask, request, jsonify
from transformers import pipeline

app = Flask(__name__)

# Load the conversational model
chatbot = pipeline('conversational', model='microsoft/DialoGPT-medium')

@app.route('/', methods=['POST'])
def main():
    user_input = request.json.get('message')
    if not user_input:
        return jsonify({"error": "No message provided"}), 400

    # Generate a response using the chatbot model
    conversation = chatbot(user_input)
    response = conversation.generated_responses[-1]

    return jsonify({"response": response})

if __name__ == '__main__':
    app.run(debug=True)