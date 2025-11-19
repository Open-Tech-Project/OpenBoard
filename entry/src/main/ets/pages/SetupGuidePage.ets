import { OpenBoardTheme } from '../InputMethodExtensionAbility/model/Theme';

@Entry
@Component
struct SetupGuidePage {
  build() {
    Navigation() {
      Column({ space: 16 }) {
        Text('إعداد لوحة مفاتيح OpenBoard')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(OpenBoardTheme.primaryText)

        Column({ space: 12 }) {
          Text('1) افتح إعدادات النظام')
            .fontSize(18)
            .fontColor(OpenBoardTheme.primaryText)
          Text('2) انتقل إلى اللغات والإدخال > لوحات المفاتيح')
            .fontSize(18)
            .fontColor(OpenBoardTheme.primaryText)
          Text('3) فعّل OpenBoard من قائمة لوحات المفاتيح')
            .fontSize(18)
            .fontColor(OpenBoardTheme.primaryText)
          Text('4) عيّن OpenBoard كلوحة المفاتيح الافتراضية')
            .fontSize(18)
            .fontColor(OpenBoardTheme.primaryText)
          Text('5) لعرض اللغات المتاحة، اضغط مفتاح المسافة داخل اللوحة')
            .fontSize(18)
            .fontColor(OpenBoardTheme.secondaryText)
        }
        .padding({ left: 8, right: 8 })

        Divider()

        Text('ملاحظات')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(OpenBoardTheme.primaryText)
        Text('لا توجد عناصر تفاعلية في هذه الصفحة. اتبع الخطوات أعلاه لإكمال الإعداد.')
          .fontSize(16)
          .fontColor(OpenBoardTheme.secondaryText)
          .lineHeight(22)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 20 })
      .backgroundColor(OpenBoardTheme.background)
    }
    .title('دليل الإعداد')
    .titleMode(NavigationTitleMode.Mini)
  }
}