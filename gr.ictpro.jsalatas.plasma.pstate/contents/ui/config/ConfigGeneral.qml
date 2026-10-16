import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    property alias cfg_useDefaultIcon: useDefaultIconCheckbox.checked
    property alias cfg_showIntelGPU: showIntelGPUCheckbox.checked
    property string cfg_customIcon: Plasmoid.configuration.customIcon
    property alias cfg_useSudoForReading: useSudoForReadingCheckbox.checked

    property bool cfg_useDefaultIconDefault
    property bool cfg_showIntelGPUDefault
    property string cfg_customIconDefault
    property bool cfg_useSudoForReadingDefault

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: useDefaultIconCheckbox
            text: i18n('Use Default Icon')
        }

        IconPicker {
            Kirigami.FormData.label: i18n("Custom Icon:")
            currentIcon: cfg_customIcon
            onIconPicked: iconName => cfg_customIcon = iconName
            onIconCleared: {
                useDefaultIconCheckbox.checked = true
            }
            enabled: !useDefaultIconCheckbox.checked
        }

        QQC2.CheckBox {
            id: showIntelGPUCheckbox
            text: i18n('Show Intel GPU')
        }

        QQC2.CheckBox {
            id: useSudoForReadingCheckbox
            text: i18n('Use sudo for reading values')
        }
    }
}
