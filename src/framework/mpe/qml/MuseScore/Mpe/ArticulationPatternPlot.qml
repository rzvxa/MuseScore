/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-CLA-applies
 *
 * MuseScore
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore BVBA and others
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import MuseScore.Ui 1.0
import MuseScore.UiComponents 1.0
import MuseScore.Mpe 1.0

Item {
    id: root

    property QtObject patternModel: null

    property bool thumbnailModeOn: false

    property bool showArrangement: false
    property bool showPitch: false
    property bool showExpression: false

    property color arrangementLineColor: "#2093FE"
    property color pitchLineColor: "#27A341"
    property color expressionLineColor: "#F25555"

    property real durationFactor: root.patternModel ? root.patternModel.durationFactor : 1.0
    property real timestampShiftFactor: root.patternModel ? root.patternModel.timestampShiftFactor : 0.0

    property int selectedPitchOffsetIndex: root.patternModel ? root.patternModel.selectedPitchOffsetIndex : -1
    property var pitchOffsets: root.patternModel ? root.patternModel.pitchOffsets : []

    property int selectedDynamicOffsetIndex: root.patternModel ? root.patternModel.selectedDynamicOffsetIndex : -1
    property var dynamicOffsets: root.patternModel ? root.patternModel.dynamicOffsets : []

    width: 1000
    height: 1000

    QtObject {
        id: prv

        readonly property int displayableSteps: 24 // from -5 to 15, where 10 is 100% of duration
        readonly property real pixelsPerStep: Math.max(root.width, root.height) / prv.displayableSteps
        readonly property int stepsToFullScale: 10 // amount of steps from 0% to 100% of duration
        readonly property real pixelsToFullScale: prv.stepsToFullScale * prv.pixelsPerStep // amount of steps from 0% to 100% of duration in pixels
        readonly property real precision: 0.1

        readonly property real pointHandleDiameter: 8

        readonly property real centerXRatio: 0.25
        readonly property real centerYRatio: 0.5

        readonly property real centerX: root.width * prv.centerXRatio
        readonly property real centerY: root.height * prv.centerYRatio

        readonly property real legendX: root.width * 0.05
        readonly property real legendY: root.height * 0.05
        readonly property real legendSampleSize: 12

        function applyXShiftToCoordindates(curvePoint, xShift, xSpanFactor) {
            return Qt.point(curvePoint.x * xSpanFactor + xShift, curvePoint.y)
        }

        function coordinatesToPixels(curvePoint) {
            return Qt.point(prv.centerX + (curvePoint.x * prv.pixelsToFullScale),
                            prv.centerY - (curvePoint.y * prv.pixelsToFullScale))
        }

        function coordinatesFromPixels(pixelsPoint) {
            return Qt.point((pixelsPoint.x - prv.centerX) / prv.pixelsToFullScale,
                            (prv.centerY - pixelsPoint.y) / prv.pixelsToFullScale)
        }

        function legendsList() {
            var result = []

            if (root.showArrangement) {
                result.push({ title : qsTrc("mpe", "Time line"), color: root.arrangementLineColor})
            }

            if (root.showPitch) {
                result.push({ title : qsTrc("mpe", "Pitch curve"), color: root.pitchLineColor})
            }

            if (root.showExpression) {
                result.push({ title : qsTrc("mpe", "Expression curve"), color: root.expressionLineColor})
            }

            return result
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent

        onPaint: {
            var ctx = canvas.context

            if (!ctx) {
                ctx = getContext("2d")
            }

            canvas.fillBackground(ctx, "#4D4D4D")

            canvas.drawGrid(ctx, 1, "#5D5D5D")

            canvas.drawAxisX(ctx, 2, "#FFFFFF")
            canvas.drawAxisY(ctx, 2, "#FFFFFF")

            if (!root.patternModel) {
                return
            }

            if (!root.thumbnailModeOn) {
                canvas.drawAvailableLegends(ctx, "#FFFFFF")
            }

            if (root.showArrangement) {
                canvas.drawArrangement(ctx)
            }

            if (root.showPitch) {
                canvas.drawPitchCurve(ctx)
            }

            if (root.showExpression) {
                canvas.drawExpressionCurve(ctx)
            }
        }

        function fillBackground(ctx, color) {
            ctx.fillStyle = color
            ctx.fillRect(0, 0, canvas.width, canvas.height)
        }

        function drawGrid(ctx, lineWidth, color) {
            ctx.fillStyle = color

            for (var i = 0; i < prv.displayableSteps; ++i) {
                var idx = i * prv.pixelsPerStep - lineWidth / 2
                ctx.fillRect(idx, 0, lineWidth, canvas.height)
                ctx.fillRect(0, idx, canvas.width, lineWidth)
            }
        }

        function drawAxisX(ctx, lineWidth, color) {
            ctx.fillStyle = color
            ctx.fillRect(0, (canvas.height * prv.centerYRatio) - (lineWidth / 2), canvas.width, lineWidth)

            if (root.thumbnailModeOn) {
                return
            }

            for (var i = -prv.stepsToFullScale / 2; i <= prv.stepsToFullScale; ++i) {
                var textNum = i * prv.precision
                ctx.fillText(textNum.toFixed(1),
                             prv.centerX + (i * prv.pixelsPerStep) - 8,
                             prv.centerY + 24)
            }
        }

        function drawAxisY(ctx, lineWidth, color) {
            ctx.fillStyle = color
            ctx.fillRect((canvas.width * prv.centerXRatio) - (lineWidth / 2), 0, lineWidth, canvas.height)
        }

        function drawAvailableLegends(ctx, textColor) {
            var legends = prv.legendsList()

            for (var i = 0; i < legends.length; ++i) {
                drawLegend(ctx, prv.legendX, prv.legendY + (i * prv.legendSampleSize) + 12, legends[i].color, textColor, legends[i].title)
            }
        }

        function drawLegend(ctx, x, y, sampleColor, textColor, text) {
            if (root.thumbnailModeOn) {
                return
            }

            ctx.fillStyle = sampleColor
            ctx.fillRect(x, y, prv.legendSampleSize, prv.legendSampleSize)

            ctx.fillStyle = textColor
            ctx.fillText("- " + text, x + prv.legendSampleSize + 4, y + (prv.legendSampleSize / 2) + 4)
        }

        function drawCurve(ctx, points, posXShift, spanFactor, lineWidth, lineColor) {
            ctx.strokeStyle = lineColor
            ctx.lineWidth = lineWidth
            ctx.lineJoin = "round"

            ctx.beginPath()

            for (var i = 0; i < points.length; ++i) {
                var position = prv.coordinatesToPixels(prv.applyXShiftToCoordindates(points[i], posXShift, spanFactor))

                if (i == 0) {
                    ctx.moveTo(position.x, position.y)
                } else {
                    ctx.lineTo(position.x, position.y)
                }
            }

            ctx.stroke()
        }

        function drawPointHandlers(ctx, points, posXShift, spanFactor, selectedPointIdx, handlePrimaryFillColor, handleSecondaryFillColor) {
            if (root.thumbnailModeOn) {
                return
            }

            for (var i = 0; i < points.length; ++i) {
                var position = prv.coordinatesToPixels(prv.applyXShiftToCoordindates(points[i], posXShift, spanFactor))

                var outerDiameter = prv.pointHandleDiameter
                var innerDiameter = prv.pointHandleDiameter / 2

                if (i === selectedPointIdx) {
                    outerDiameter *= 2
                    innerDiameter *= 2
                }

                canvas.drawCircle(ctx, position, handlePrimaryFillColor, outerDiameter)
                canvas.drawCircle(ctx, position, handleSecondaryFillColor, innerDiameter)
            }
        }

        function drawCircle(ctx, position, fillColor, diameter) {
            ctx.beginPath()
            ctx.ellipse(position.x - (diameter / 2),
                        position.y - (diameter / 2),
                        diameter,
                        diameter)

            ctx.fillStyle = fillColor
            ctx.fill()
        }

        function drawArrangement(ctx) {
            var arrangementPoints = [ Qt.point(root.timestampShiftFactor, 0.0), Qt.point(root.timestampShiftFactor + root.durationFactor, 0.0)]

            canvas.drawCurve(ctx, arrangementPoints, 0.0, 1.0, 2, root.arrangementLineColor)
            canvas.drawPointHandlers(ctx, arrangementPoints, 0.0, 1.0, 0, "#FFFFFF", root.arrangementLineColor)
        }

        function drawPitchCurve(ctx) {
            canvas.drawCurve(ctx, root.pitchOffsets, root.timestampShiftFactor, root.durationFactor, 2, root.pitchLineColor)
            canvas.drawPointHandlers(ctx, root.pitchOffsets, root.timestampShiftFactor, root.durationFactor, root.selectedPitchOffsetIndex, "#FFFFFF", root.pitchLineColor)
        }

        function drawExpressionCurve(ctx) {
            canvas.drawCurve(ctx, root.dynamicOffsets, root.timestampShiftFactor, root.durationFactor, 2, root.expressionLineColor)
            canvas.drawPointHandlers(ctx, root.dynamicOffsets, root.timestampShiftFactor, root.durationFactor, root.selectedDynamicOffsetIndex, "#FFFFFF", root.expressionLineColor)
        }
    }

    onShowArrangementChanged: {
        canvas.requestPaint()
    }

    onShowPitchChanged: {
        canvas.requestPaint()
    }

    onShowExpressionChanged: {
        canvas.requestPaint()
    }

    onDurationFactorChanged: {
        if (root.showArrangement) {
            canvas.requestPaint()
        }
    }

    onTimestampShiftFactorChanged: {
        if (root.showArrangement) {
            canvas.requestPaint()
        }
    }

    onPitchOffsetsChanged: {
        if (root.showPitch) {
            canvas.requestPaint()
        }
    }

    onSelectedPitchOffsetIndexChanged: {
        if (root.showPitch) {
            canvas.requestPaint()
        }
    }

    onDynamicOffsetsChanged: {
        if (root.showExpression) {
            canvas.requestPaint()
        }
    }

    onSelectedDynamicOffsetIndexChanged: {
        if (root.showExpression) {
            canvas.requestPaint()
        }
    }
}