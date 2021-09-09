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
#ifndef MU_INSPECTOR_PEDALSSETTINGSMODEL_H
#define MU_INSPECTOR_PEDALSSETTINGSMODEL_H

#include "linesettingsmodel.h"

namespace mu::inspector {
class PedalSettingsModel : public LineSettingsModel
{
    Q_OBJECT

    Q_PROPERTY(PropertyItem * lineType READ lineType CONSTANT)
    Q_PROPERTY(bool pedalSymbolVisible READ pedalSymbolVisible WRITE setPedalSymbolVisible NOTIFY pedalSymbolVisibleChanged)
    Q_PROPERTY(bool isChangingLineVisibilityAllowed READ isChangingLineVisibilityAllowed NOTIFY isChangingLineVisibilityAllowedChanged)

public:
    explicit PedalSettingsModel(QObject* parent, IElementRepositoryService* repository);

    PropertyItem* lineType() const;
    bool pedalSymbolVisible() const;
    bool isChangingLineVisibilityAllowed() const;

public slots:
    void setPedalSymbolVisible(bool visible);

signals:
    void pedalSymbolVisibleChanged();
    void isChangingLineVisibilityAllowedChanged();

private:
    bool isStarSymbolVisible() const;

    void createProperties() override;
    void loadProperties() override;
    bool isTextVisible(TextType type) const override;

    void setLineType(int newType);

    PropertyItem* m_lineType = nullptr;
};
}

#endif // MU_INSPECTOR_PEDALSSETTINGSMODEL_H