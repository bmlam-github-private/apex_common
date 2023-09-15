import json
import smtplib
from email.mime.text import MIMEText

def send_email(metadata, content):
    # Replace these values with your actual IMAP server settings
    smtp_server = 'your_smtp_server'
    smtp_port = 587  # or the appropriate port for your SMTP server
    smtp_username = 'your_smtp_username'
    smtp_password = 'your_smtp_password'

    # Prepare the email message
    msg = MIMEText(content)
    msg['Subject'] = metadata["subject"]
    msg['From'] = metadata["from"]
    msg['To'] = metadata["to"]

    try:
        # Connect to the SMTP server and send the email
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()  # Use TLS encryption
            server.login(smtp_username, smtp_password)
            server.send_message(msg)

        print("Email sent successfully.")
    except Exception as e:
        print("Failed to send the email:", str(e))

""" example json
{
  "metadata": {
    "to": "recipient@example.com",
    "from": "sender@example.com",
    "subject": "Test Email"
  },
  "content": "This is the email content."
}

"""
if __name__ == "__main__":
    with open("email_data.json") as json_file:
        data = json.load(json_file)
        metadata = data["metadata"]
        content = data["content"]

        send_email(metadata, content)
