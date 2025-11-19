import { display } from '@kit.ArkUI';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
import { BusinessError } from '@kit.BasicServicesKit';

const inputMethodAbility: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();

export class KeyboardController {
  private mContext: InputMethodExtensionContext | undefined = undefined;
  private panel: inputMethodEngine.Panel | undefined = undefined;
  private textInputClient: inputMethodEngine.InputClient | undefined = undefined;
  private currentEnterKeyType: number = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
  private enterKeyTypeCallback?: (enterKeyType: number) => void;

  constructor() {}

  public onCreate(context: InputMethodExtensionContext): void {
    console.info('OpenBoard Keyboard: KeyboardController onCreate called');
    this.mContext = context;
    this.initWindow();
    this.registerListener();
  }

  public onDestroy(): void {
    this.unRegisterListener();
    this.textInputClient = undefined;
    this.currentEnterKeyType = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
    if (this.panel) {
      try {
        inputMethodAbility.destroyPanel(this.panel);
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to destroy panel. Code: ${error.code}, Msg: ${error.message}`);
      }
      this.panel = undefined;
    }
    if (this.mContext) {
      try {
        this.mContext.destroy();
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to destroy context. Code: ${error.code}, Msg: ${error.message}`);
      }
      this.mContext = undefined;
    }
  }

  public hideKeyboard(): void {
    if (this.panel) {
      try {
        inputMethodAbility.destroyPanel(this.panel);
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to hide panel. Code: ${error.code}, Msg: ${error.message}`);
      }
      this.panel = undefined;
    }
    this.textInputClient = undefined;
    this.currentEnterKeyType = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
  }

  public insertText(text: string): void {
    if (this.textInputClient) {
      try {
        this.textInputClient.insertText(text);
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to insert text. Code: ${error.code}, Msg: ${error.message}`);
      }
    }
  }

  public deleteForward(length: number): void {
    if (this.textInputClient) {
      try {
        this.textInputClient.deleteForward(length);
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to delete forward. Code: ${error.code}, Msg: ${error.message}`);
      }
    }
  }

  public deleteBackward(length: number): void {
    if (this.textInputClient) {
      try {
        this.textInputClient.deleteBackward(length);
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to delete backward. Code: ${error.code}, Msg: ${error.message}`);
      }
    }
  }

  public sendEnterKey(): void {
    if (this.textInputClient) {
      try {
        this.textInputClient.sendKeyFunction(this.currentEnterKeyType);
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to send enter key. Code: ${error.code}, Msg: ${error.message}`);
        try {
          this.textInputClient.insertText('\n');
        } catch (insertErr) {
          const insertError = insertErr as BusinessError;
          console.error(`OpenBoard Keyboard: Failed to insert newline. Code: ${insertError.code}, Msg: ${insertError.message}`);
        }
      }
    }
  }

  public getCurrentEnterKeyType(): number {
    return this.currentEnterKeyType;
  }

  public setEnterKeyTypeCallback(callback: (enterKeyType: number) => void): void {
    this.enterKeyTypeCallback = callback;
  }

  private initWindow(): void {
    if (this.mContext === undefined) {
      return;
    }
    let dWidth: number = 360;
    let dHeight: number = 640;
    try {
      const dis = display.getDefaultDisplaySync();
      dWidth = dis.width;
      dHeight = dis.height;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`OpenBoard Keyboard: Failed to get display. Code: ${error.code}, Msg: ${error.message}`);
    }
    let keyHeightRate = dHeight >= 1200 ? 0.35 : 0.40;
    let keyHeight = dHeight * keyHeightRate;
    let nonBarPosition = dHeight - keyHeight;

    const panelInfo: inputMethodEngine.PanelInfo = {
      type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
      flag: inputMethodEngine.PanelFlag.FLG_FIXED
    };

    inputMethodAbility.createPanel(this.mContext, panelInfo).then(async (inputPanel: inputMethodEngine.Panel) => {
      try {
        this.panel = inputPanel;
        if (this.panel) {
          try {
            await this.panel.resize(dWidth, keyHeight);
            await this.panel.moveTo(0, nonBarPosition);
            await this.panel.setUiContent('InputMethodExtensionAbility/pages/Index');
            console.info(`OpenBoard Keyboard: Panel initialized with fixed height ${keyHeight}px`);
          } catch (resizeErr) {
            const error = resizeErr as BusinessError;
            console.error(`OpenBoard Keyboard: Failed to resize/move panel. Code: ${error.code}, Msg: ${error.message}`);
          }
        }
      } catch (err) {
        const error = err as BusinessError;
        console.error(`OpenBoard Keyboard: Failed to initialize panel UI. Code: ${error.code}, Msg: ${error.message}`);
      }
    }).catch((err: BusinessError) => {
      console.error(`Failed to createPanel, code: ${err.code}, message: ${err.message}`);
    });
  }

  private registerListener(): void {
    this.registerInputListener();
  }

  private registerInputListener(): void {
    inputMethodAbility.on('inputStart', (_, textInputClient) => {
      this.textInputClient = textInputClient;
      this.updateEnterKeyType();
      this.hideIfDestroyedAndRecreate();
    });
    inputMethodAbility.on('inputStop', this.inputStopCallback);
  }

  private hideIfDestroyedAndRecreate(): void {
    if (!this.panel) {
      this.initWindow();
    }
  }

  private updateEnterKeyType(): void {
    if (!this.textInputClient) {
      return;
    }
    try {
      this.textInputClient.getEditorAttribute((err: BusinessError, editorAttribute: inputMethodEngine.EditorAttribute) => {
        if (err) {
          console.error(`OpenBoard Keyboard: Failed to get editor attribute. Code: ${err.code}, Msg: ${err.message}`);
          this.currentEnterKeyType = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
          return;
        }
        this.currentEnterKeyType = editorAttribute.enterKeyType;
        console.info(`OpenBoard Keyboard: Enter key type updated to ${this.currentEnterKeyType}`);
        if (this.enterKeyTypeCallback) {
          this.enterKeyTypeCallback(this.currentEnterKeyType);
        }
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`OpenBoard Keyboard: Failed to call getEditorAttribute. Code: ${error.code}, Msg: ${error.message}`);
      this.currentEnterKeyType = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
    }
  }

  private inputStopCallback = (): void => {
    console.info('OpenBoard Keyboard: Input stopped');
    this.textInputClient = undefined;
    this.currentEnterKeyType = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
  };

  private unRegisterListener(): void {
    inputMethodAbility.off('inputStart');
    inputMethodAbility.off('inputStop', this.inputStopCallback);
  }
}

const keyboardController = new KeyboardController();
export default keyboardController;