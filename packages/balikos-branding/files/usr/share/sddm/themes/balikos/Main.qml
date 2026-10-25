import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#071a2b"

    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Image {
            source: "logo.png"
            width: 220
            height: 220
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "BalıkOS"
            color: "#e0f2fe"
            font.pixelSize: 42
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextField {
            id: password
            width: 340
            height: 44
            placeholderText: "Parola"
            echoMode: TextInput.Password
            horizontalAlignment: TextInput.AlignHCenter
            onAccepted: sddm.login(userModel.lastUser, password.text, sessionModel.lastIndex)
        }

        Button {
            text: "Giriş"
            width: 340
            height: 44
            onClicked: sddm.login(userModel.lastUser, password.text, sessionModel.lastIndex)
        }

        Text {
            text: "BalıkOS · canlı ve kurulum ortamı"
            color: "#7dd3fc"
            font.pixelSize: 15
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
