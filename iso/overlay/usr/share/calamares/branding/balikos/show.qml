/* BalıkOS Calamares slideshow */
import QtQuick 2.15;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 30000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "#071a2b"

            Image {
                source: "slide-balikos.png"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "BalıkOS kuruluyor..."
                color: "#bae6fd"
                font.pixelSize: 24
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 48
            }
        }
    }
}
