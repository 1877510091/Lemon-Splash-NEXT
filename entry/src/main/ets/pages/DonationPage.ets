import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct DonationPage {

  async saveResourceToAlbum(resource: Resource, fileName: string): Promise<boolean> {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let resourceMgr = context.resourceManager;

      let fileData = await resourceMgr.getMediaContent(resource);
      let buffer = fileData.buffer;

      let helper = photoAccessHelper.getPhotoAccessHelper(context);
      let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      let file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, buffer);
      await fs.close(file.fd);

      return true;
    } catch (e) {
      console.error(`保存失败 ${fileName}: ${JSON.stringify(e as object)}`);
      return false;
    }
  }

  async requestPermissionAndSave() {
    let context = getContext(this) as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    let permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO'];

    try {
      let data = await atManager.requestPermissionsFromUser(context, permissions);
      let isAuth = data.authResults.every((result: number) => result === 0);

      if (isAuth) {
        this.startSaving();
      } else {
        promptAction.showToast({ message: '您拒绝了相册权限，无法保存图片' });
      }
    } catch (err) {
      console.error('权限申请失败:', JSON.stringify(err as object));
      this.startSaving();
    }
  }
  async startSaving() {
    try {
      promptAction.showToast({ message: '图片已删除，请手动截图保存' });
    } catch (e) {
      promptAction.showToast({ message: '保存失败，请手动截图' });
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24).fontColor(['#E91E63'])
          .onClick(() => router.back())
        Text("赞赏作者[渠道已关闭]")
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#E91E63')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).width('100%').padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Image($r('app.media.icon'))
            .width(80).height(80)
            .borderRadius(20)
            .margin({ top: 30, bottom: 15 })

          Text("Lemon Splash")
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#424242')

          Text("哎呀哎呀哎呀，感谢我各位总啊，真是太性情，太通透了！")
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#E91E63')
            .textAlign(TextAlign.Center).lineHeight(24)
            .margin({ top: 10, bottom: 40 }).padding({ left: 20, right: 20 })
          Row({ space: 30 }) {
            Column() {
              Blank()
                .width(130).height(130).borderRadius(10)
                .backgroundColor(Color.White).padding(5)
                .shadow({ radius: 10, color: 'rgba(233, 30, 99, 0.2)', offsetY: 5 })
              Text("微信支付[已关闭]").fontSize(14).fontColor('#09BB07').margin({ top: 10 }).fontWeight(FontWeight.Medium)
            }
            Column() {
              Blank()
                .width(130).height(130).borderRadius(10)
                .backgroundColor(Color.White).padding(5)
                .shadow({ radius: 10, color: 'rgba(233, 30, 99, 0.2)', offsetY: 5 })
              Text("支付宝[已关闭]").fontSize(14).fontColor('#0277BD').margin({ top: 10 }).fontWeight(FontWeight.Medium)
            }
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .margin({ bottom: 50 })
          Button("点击保存赞赏码🌹")
            .backgroundColor('#999999')
            .width('70%')
            .height(50)
            .shadow({ radius: 10, color: 'rgba(153, 153, 153, 0.3)', offsetY: 5 })
            .onClick(() => {
              promptAction.showToast({ message: '赞赏渠道已关闭' });
            })

          Text("感谢您的支持！")
            .fontSize(12).fontColor(Color.Gray).margin({ top: 20 })
        }
        .width('100%').padding({ bottom: 30 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#FFF0F5').padding({ top: 48 })
  }
}