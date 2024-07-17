import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

import org.qfield
import org.qgis
import Theme

import "qrc:/qml" as QFieldItems

Item {
  id: plugin

  property var mainWindow: iface.mainWindow()
  property var mapCanvas: iface.mapCanvas()
  property var canvasMenu: iface.findItemByObjectName('canvasMenu')

  Component.onCompleted: {
    iface.addItemToCanvasActionsToolbar(pluginButtonsContainer)
  }

  Marker {
    id: startMarker
    parent: mapCanvas
    visible: routeStartPoint != undefined
    
    sourcePosition: routeStartPoint ? routeStartPoint : GeometryUtils.emptyPoint()
    sourceCrs: routeRenderer.geometryWrapper.crs
    destinationCrs: mapCanvas.mapSettings.destinationCrs
    fillColor: "green"
  }
  
  
  Marker {
    id: midMarker
    parent: mapCanvas
    visible: routeMidPoint != undefined
    
    sourcePosition: routeMidPoint ? routeMidPoint : GeometryUtils.emptyPoint()
    sourceCrs: routeRenderer.geometryWrapper.crs
    destinationCrs: mapCanvas.mapSettings.destinationCrs
    fillColor: "gold"
  }

  Marker {
    id: endMarker
    parent: mapCanvas
    visible: routeEndPoint != undefined

    sourcePosition: routeEndPoint ? routeEndPoint : GeometryUtils.emptyPoint()
    sourceCrs: routeRenderer.geometryWrapper.crs
    destinationCrs: mapCanvas.mapSettings.destinationCrs
    fillColor: "orangered"
  }

  QFieldItems.GeometryRenderer {
    id: routeRenderer
    parent: mapCanvas
    mapSettings: mapCanvas.mapSettings
    geometryWrapper.crs: CoordinateReferenceSystemUtils.wgs84Crs()
    lineWidth: 6
    color: "#99562b7a"
  }

  Rectangle {
    id: pluginButtonsContainer
    width: childrenRect.width + 10
    height: 48
    radius: height / 2
    color: "#015491"
    
    QfToolButton {
      id: addStartPointButton
      anchors.left: parent.left
      anchors.leftMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      width: parent.height - 10
      height: width
      iconSource: 'routeStartIcon.svg'
      iconColor: "white"
      bgcolor: routeStartPoint != undefined ? "green" : "transparent"
      round: true

      onClicked: {
        routeStartPoint = GeometryUtils.reprojectPointToWgs84(canvasMenu.point, mapCanvas.mapSettings.destinationCrs)
        if (routeEndPoint != undefined) {
          getRoute()
        }
        canvasMenu.close()
      }
    }
    
    QfToolButton {
      id: addMidPointButton
      anchors.left: addStartPointButton.right
      anchors.leftMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      width: parent.height - 10
      height: width
      iconSource: 'routeMidIcon.svg'
      iconColor: "white"
      bgcolor: routeMidPoint != undefined ? "gold" : "transparent"
      round: true

      onClicked: {
        routeMidPoint = GeometryUtils.reprojectPointToWgs84(canvasMenu.point, mapCanvas.mapSettings.destinationCrs)
        if (routeMidPoint != undefined && routeEndPoint != undefined) {
          getRoute()
        }
        canvasMenu.close()
      }
    }
    
    QfToolButton {
      id: addEndPointButton
      anchors.left: addMidPointButton.right
      anchors.leftMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      width: parent.height - 10
      height: width
      iconSource: 'routeEndIcon.svg'
      iconColor: "white"
      bgcolor: routeEndPoint != undefined ? "orangered" : "transparent"
      round: true

      onClicked: {
        routeEndPoint = GeometryUtils.reprojectPointToWgs84(canvasMenu.point, mapCanvas.mapSettings.destinationCrs)
        if (routeStartPoint != undefined) {
          getRoute()
        }
        canvasMenu.close()
      }
    }
    
    QfToolButton {
      id: clearPointsButton
      anchors.left: addEndPointButton.right
      anchors.leftMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      width: parent.height - 10
      height: width
      iconSource: 'routeClearIcon.svg'
      iconColor: "white"
      round: true
      enabled: routeStartPoint != undefined || routeEndPoint != undefined
      opacity: enabled ? 1.0 : 0.5

      onClicked: {
        routeStartPoint = undefined
        routeMidPoint = undefined
        routeEndPoint = undefined
        routeRenderer.geometryWrapper.qgsGeometry = GeometryUtils.createGeometryFromWkt("")
        canvasMenu.close()
      }
    }
  }
  
  property var routeStartPoint: undefined
  property var routeMidPoint: undefined
  property var routeEndPoint: undefined
  property var routeRequest: undefined
  property var routeJson: undefined

  function getRoute() {
    routeRequest = new XMLHttpRequest()
    routeRequest.onreadystatechange = () => {
      if (routeRequest.readyState === XMLHttpRequest.DONE) {
        routeJson = JSON.parse(routeRequest.response)
        processRoute()
      }
    }
    const startBlock = routeStartPoint.x+","+routeStartPoint.y+";"
    const midBlock = routeMidPoint != undefined ? routeMidPoint.x+","+routeMidPoint.y+";" : ""
    const endBlock = routeEndPoint.x+","+routeEndPoint.y
    const url = "https://routing.openstreetmap.de/routed-car/route/v1/driving/"+startBlock+midBlock+endBlock+"?overview=false&geometries=geojson&steps=true"
    console.log(url)
    
    routeRequest.open("GET", url)
    routeRequest.send()
  }

  function processRoute() {
    if (routeJson !== undefined) {
      let points = []
      for (let leg of routeJson['routes'][0]['legs']) {
        for (let step of leg['steps']) {
          for (let coordinates of step['geometry']['coordinates']) {
            points.push(coordinates[0] + ' ' + coordinates[1])
          }
        }
      }
      const wkt = "LINESTRING(" + points.join(",") + ")"
      routeRenderer.geometryWrapper.qgsGeometry = GeometryUtils.createGeometryFromWkt(wkt)
    }
  }
}
