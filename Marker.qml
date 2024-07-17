import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

import org.qfield
import org.qgis
import Theme

Shape {
  id: marker
  
  property alias sourcePosition: _cts.sourcePosition
  property alias sourceCrs: _cts.sourceCrs
  property alias destinationCrs: _cts.destinationCrs
  property color fillColor: "gray"


  property CoordinateTransformer ct: CoordinateTransformer {
    id: _cts
    transformContext: qgisProject ? qgisProject.transformContext : CoordinateReferenceSystemUtils.emptyTransformContext()
  }

  MapToScreen {
    id: mapToScreenStart
    mapSettings: mapCanvas.mapSettings
    mapPoint: _cts.projectedPosition
  }

  x: mapToScreenStart.screenPoint.x - width / 2
  y: mapToScreenStart.screenPoint.y - height + 4

  width: 36
  height: 40

  ShapePath {
    strokeWidth: 3
    strokeColor: "white"
    strokeStyle: ShapePath.SolidLine
    joinStyle: ShapePath.MiterJoin
    fillColor: marker.fillColor

    startX: 6
    startY: 16
    PathArc {
      x: 30
      y: 16
      radiusX: 12
      radiusY: 14
    }
    PathArc {
      x: 18
      y: 36
      radiusX: 36
      radiusY: 36
    }
    PathArc {
      x: 6
      y: 16
      radiusX: 36
      radiusY: 36
    }
  }

  Rectangle {
    x: 13
    y: 9
    width: 10
    height: 10
    color: "white"
    radius: 4
  }
}
