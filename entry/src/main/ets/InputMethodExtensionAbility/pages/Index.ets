import { OpenBoardTheme } from '../model/Theme';
import {
  arabicLayout,
  englishLayout,
  italianLayout,
  KeyAction,
  KeyboardLayout,
  KeyData,
  polishLayout,
  ShiftState,
  symbolsLayout1,
  symbolsLayout2,
  persianLayout
} from '../model/KeyboardKeyData';
import keyboardController from '../model/KeyboardController';
import predictionModel from '../model/PredictionModel';
import { display } from '@kit.ArkUI';
import { inputMethodEngine } from '@kit.IMEKit';

const EMOJI_KEY_DATA: KeyData = { mainValue: 'icon', secondaryValue: undefined, action: KeyAction.EMOJI_PANEL, flex: 1.2, shiftValue: undefined };

// TYPE DEFINITIONS
interface Position { x: number; y: number; }
interface LongPressInfo { key: KeyData; initialPosition: Position; }
interface SingleCharPopupInfo { char: string; position: Position; }
type LanguageCode = 'en' | 'ar' | 'it' | 'pl' | 'fa';
enum LayoutSwipeDirection { Left, Right }
const ALLOWED_LANGUAGES: string[] = ['en', 'ar', 'it', 'pl', 'fa'];
const EMOJI_CATEGORIES: string[] = ['Smileys & Emotion', 'People', 'Animals & Nature', 'Food & Drink', 'Activity & Event', 'Travel & Places', 'Objects', 'Symbols', 'Flags'];

// FUNKCJE POMOCNICZE
function getLanguageName(code: LanguageCode): string {
  switch (code) {
    case 'ar': return '╨и┬з╨йтАЮ╨итДЦ╨и╥▒╨и╨Б╨й╥а╨и┬й';
    case 'en': return 'English';
    case 'it': return 'Italiano';
    case 'pl': return 'Polski';
    case 'fa': return '╨й╥Т╨и┬з╨и╥▒╨и╤Ц╨л╥в';
    default: return 'English';
  }
}

function getVoiceDictationStatus(code: LanguageCode): string {
  switch (code) {
    case 'en': return 'Typing with voice...';
    case 'pl': return 'Pisz╨Ф╥╖ g╨Х╙оosem...';
    case 'it': return 'Digitazione vocale...';
    case 'ar': return '╨й╥У╨и╙Ш╨и┬з╨и╨Б╨и┬й ╨и╙й╨й╥▓╨и╙Ш╨й╥а╨и┬й...';
    case 'fa': return '╨и╙Ш╨и┬з╨л╥в╨й╥л ╨и╙й╨й╥▓╨и╙Ш╨л╥в...';
    default: return 'Typing with voice...';
  }
}

// KOMPONENTY
@Component
struct KeyPopup {
  @Prop info: LongPressInfo;
  @Prop hoveredChar: string | null;
  @Prop keyWidth: number;
  build() {
    Row({ space: 8 }) {
      ForEach((this.info.key.secondaryValue ?? '').split(','), (char: string) => {
        Text(char)
          .fontSize(22)
          .fontWeight(500)
          .fontColor(OpenBoardTheme.primaryText)
          .width(this.keyWidth)
          .height(50)
          .textAlign(TextAlign.Center)
          .backgroundColor(char === this.hoveredChar ? OpenBoardTheme.accent : OpenBoardTheme.specialKey)
          .borderRadius(8)
          .animation({ duration: 50 })
      })
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor(OpenBoardTheme.surface)
    .borderRadius(12)
    .shadow({ radius: 10, color: '#60000000', offsetY: 4 })
  }
}

@Component
struct SingleKeyPopup {
  @Prop char: string;
  build() {
    Column() {
      Text(this.char)
        .fontSize(24)
        .fontWeight(400)
        .fontColor(OpenBoardTheme.primaryText)
    }
    .width(50)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(OpenBoardTheme.surface)
    .borderRadius(12)
  }
}

@Component
struct LanguageIndicator {
  @Prop languageName: string;
  build() {
    Column() {
      Text(this.languageName)
        .fontSize(28)
        .fontWeight(500)
        .fontColor('#FFFFFF')
        .padding({ left: 24, right: 24, top: 12, bottom: 12 })
    }
    .backgroundColor('rgba(0, 0, 0, 0.85)')
    .borderRadius(16)
    .shadow({ radius: 20, color: '#40000000', offsetY: 4 })
  }
}

@Component
struct KeyView {
  @Prop keyData: KeyData;
  @Prop shiftState: ShiftState;
  @Prop currentLanguage: LanguageCode;
  @Prop availableLanguages: LanguageCode[];
  onKeyPress: (key: KeyData) => void = () => {};
  onKeyLongPress: (key: KeyData, position: Position) => void = () => {};
  onKeyContinuousPressStart: (key: KeyData) => void = () => {};
  onKeyContinuousPressEnd: (key: KeyData) => void = () => {};
  onSwipe?: (direction: LayoutSwipeDirection) => void;

  @State isPressed: boolean = false;
  @State private longPressTimer: number = -1;
  @State private longPressTriggered: boolean = false;
  @State private touchStartX: number = 0;
  @State private swipeHandled: boolean = false;

  @Prop enterKeyLabel: string;

  getDisplayValue(): string {
    if (this.keyData.action === KeyAction.Shift) {
      if (this.shiftState === ShiftState.CapsLock) return '╨▓╥о╙Ш';
      if (this.shiftState === ShiftState.On) return '╨▓╥о┬з';
      return '╨▓╥о┬з';
    }
    if (this.keyData.action === KeyAction.Enter) {
      return this.enterKeyLabel;
    }
    if (this.currentLanguage !== 'ar' && this.currentLanguage !== 'fa' && (this.shiftState === ShiftState.On || this.shiftState === ShiftState.CapsLock)) {
      return this.keyData.shiftValue ?? this.keyData.mainValue;
    }
    if (this.keyData.action === KeyAction.Space) {
      if (this.availableLanguages && this.availableLanguages.length > 1) {
        return getLanguageName(this.currentLanguage);
      }
      return '';
    }
    if (this.keyData.mainValue === 'icon') {
      return '';
    }
    return this.keyData.mainValue;
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        if (this.keyData.secondaryValue) {
          Text(this.keyData.secondaryValue.split(',')[0])
            .fontSize(12)
            .fontColor(OpenBoardTheme.secondaryText)
            .lineHeight(14)
        }

        if (this.keyData.mainValue === 'icon') {
          Image($r('app.media.emoji_icon'))
            .width(20)
            .height(20)
        } else {
          Text(this.getDisplayValue())
            .fontSize(this.keyData.secondaryValue ? 18 : 20)
            .fontWeight(this.keyData.action === KeyAction.Char ? 400 : 500)
            .fontColor(OpenBoardTheme.primaryText)
            .lineHeight(this.keyData.secondaryValue ? 20 : 22)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.isPressed ?
        OpenBoardTheme.surface : (this.keyData.action === KeyAction.Char ? OpenBoardTheme.regularKey : OpenBoardTheme.specialKey))
      .borderRadius(8)
      .shadow(this.isPressed ? { radius: 10, color: '#80000000', offsetX: 0, offsetY: 2 } : { radius: 0 })
      .zIndex(this.isPressed ? 100 : 0)
      .animation({ duration: 100 })
      .onTouch((event) => {
        const touch = event.touches[0];
        if (!touch) return;
        const currentPosition: Position = { x: touch.windowX, y: touch.windowY };

        if (event.type === TouchType.Down) {
          this.touchStartX = currentPosition.x;
          this.isPressed = true;
          this.longPressTriggered = false;
          this.swipeHandled = false;

          this.longPressTimer = setTimeout(() => {
            this.longPressTriggered = true;
            this.isPressed = false;

            if (this.keyData.action === KeyAction.Backspace) {
              this.onKeyContinuousPressStart(this.keyData);
            } else if (this.keyData.secondaryValue) {
              this.onKeyLongPress(this.keyData, currentPosition);
            } else if (this.keyData.action === KeyAction.Shift) {
              this.onKeyLongPress(this.keyData, currentPosition);
            }
          }, 500);
        }

        if (event.type === TouchType.Move && this.keyData.action === KeyAction.Space) {
          const swipeDistance = Math.abs(currentPosition.x - this.touchStartX);
          const SWIPE_THRESHOLD = 30;

          if (!this.swipeHandled && swipeDistance > SWIPE_THRESHOLD) {
            clearTimeout(this.longPressTimer);
            this.longPressTriggered = true;
            this.swipeHandled = true;

            if (this.onSwipe) {
              const direction = (currentPosition.x - this.touchStartX) > 0
                ? LayoutSwipeDirection.Right
                : LayoutSwipeDirection.Left;
              this.onSwipe(direction);
            }

            this.isPressed = false;
          }
        }

        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          clearTimeout(this.longPressTimer);
          if (this.longPressTriggered && this.keyData.action === KeyAction.Backspace) {
            this.onKeyContinuousPressEnd(this.keyData);
          } else if (event.type === TouchType.Up && !this.longPressTriggered) {
            this.onKeyPress(this.keyData);
          }

          this.isPressed = false;
          this.longPressTriggered = false;
          this.touchStartX = 0;
          this.swipeHandled = false;
        }
      })
    }
    .padding({ left: 2, right: 2, top: 2, bottom: 2 })
  }
}

@Entry
@Component
struct Index {
  @State currentLanguage: LanguageCode = 'en';
  @State shiftState: ShiftState = ShiftState.Off;
  @State lastShiftTapTs: number = 0;
  @State keyboardLayout: KeyboardLayout = KeyboardLayout.Alphabet;
  @State longPressInfo: LongPressInfo | null = null;
  @State singleCharPopupInfo: SingleCharPopupInfo | null = null;
  @State hoveredChar: string | null = null;
  @State popupPosition: Position = { x: 0, y: 0 };
  @State popupKeyWidth: number = 40;
  @State rapidDeleteTimer: number = -1;
  @State enterKeyLabel: string = '╨▓╥╢╙й';
  @State availableLanguages: LanguageCode[] = ['en'];

  @State showEmojiPanel: boolean = false;
  @State emojiCategory: string = 'Smileys & Emotion';
  private emojiScroller: Scroller = new Scroller();

  @State private previousWord: string = '';
  @State private currentWord: string = '';
  @State private suggestions: string[] = ['', '', ''];

  @State private clipboardHistory: string[] = ['wklej', 'kod', '╨Х╙Щr╨У╤Цd╨Х╙оowy', 'do', 'projektu', 'OpenBoard'];

  @State private isRecording: boolean = false;
  @State private languageIndicatorOpacity: number = 0;

  // Timer for inactivity detection
  @State private inactivityTimer: number = -1;
  @State private showPreTypingToolbar: boolean = true;

  onPageShow(): void {
    console.info('OpenBoard Keyboard: UI onPageShow called');
    this.availableLanguages = ALLOWED_LANGUAGES.map((c: string) => c as LanguageCode);
    if (!this.availableLanguages.includes(this.currentLanguage)) {
      this.currentLanguage = this.availableLanguages[0];
    }
    this.startInactivityTimer();
  }

  aboutToAppear(): void {
    console.info('OpenBoard Keyboard: UI aboutToAppear called');
    keyboardController.setEnterKeyTypeCallback((enterKeyType: number) => {
      this.updateEnterKeyLabel(enterKeyType);
    });
    this.updateEnterKeyLabel(keyboardController.getCurrentEnterKeyType());
  }

  aboutToDisappear(): void {
    if (this.rapidDeleteTimer !== -1) {
      clearInterval(this.rapidDeleteTimer);
    }
    if (this.inactivityTimer !== -1) {
      clearTimeout(this.inactivityTimer);
    }
  }

  private startInactivityTimer(): void {
    if (this.inactivityTimer !== -1) {
      clearTimeout(this.inactivityTimer);
    }
    this.inactivityTimer = setTimeout(() => {
      if (!this.isRecording && !this.showEmojiPanel && this.currentWord === '') {
        this.showPreTypingToolbar = true;
      }
    }, 5000); // 5 seconds
  }

  private resetInactivityTimer(): void {
    this.showPreTypingToolbar = false;
    this.startInactivityTimer();
  }

  private updateEnterKeyLabel(enterKeyType: number): void {
    switch (enterKeyType) {
      case inputMethodEngine.ENTER_KEY_TYPE_GO:
        this.enterKeyLabel = 'Go';
        break;
      case inputMethodEngine.ENTER_KEY_TYPE_SEARCH:
        this.enterKeyLabel = 'Search';
        break;
      case inputMethodEngine.ENTER_KEY_TYPE_SEND:
        this.enterKeyLabel = 'Send';
        break;
      case inputMethodEngine.ENTER_KEY_TYPE_NEXT:
        this.enterKeyLabel = 'Next';
        break;
      case inputMethodEngine.ENTER_KEY_TYPE_DONE:
        this.enterKeyLabel = 'Done';
        break;
      case inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED:
      default:
        this.enterKeyLabel = '╨▓╥╢╙й';
        break;
    }
  }

  private handleRapidDeleteStart(): void {
    if (this.rapidDeleteTimer !== -1) {
      clearInterval(this.rapidDeleteTimer);
    }
    this.rapidDeleteTimer = setInterval(() => {
      keyboardController.deleteForward(1);
      this.onBackspaceTyped();
    }, 100);
  }

  private handleRapidDeleteEnd(): void {
    if (this.rapidDeleteTimer !== -1) {
      clearInterval(this.rapidDeleteTimer);
      this.rapidDeleteTimer = -1;
    }
  }

  private updatePopupMetrics(touchPosition: Position): void {
    if (this.longPressInfo && this.longPressInfo.key.secondaryValue) {
      this.hoveredChar = this.longPressInfo.key.secondaryValue.split(',')[0];
      this.popupPosition = {
        x: this.longPressInfo.initialPosition.x - (this.longPressInfo.key.secondaryValue.split(',').length * this.popupKeyWidth / 2),
        y: this.longPressInfo.initialPosition.y - 70
      };
    }
  }

  private handleLongPress(key: KeyData, position: Position): void {
    if (key.action === KeyAction.Shift) {
      this.shiftState = ShiftState.CapsLock;
      return;
    }
    if (key.secondaryValue) {
      this.longPressInfo = { key: key, initialPosition: position };
      this.updatePopupMetrics(position);
    }
  }

  handleKeyPress(key: KeyData): void {
    this.resetInactivityTimer();

    if (this.isRecording) {
      this.isRecording = false;
      console.info('Pisanie g╨Х╙оosem przerwane przez r╨Ф╥╖czny wpis.');
    }

    if (key.action === KeyAction.EMOJI_PANEL) {
      this.showEmojiPanel = !this.showEmojiPanel;
      return;
    }

    switch (key.action) {
      case KeyAction.Char:
        let text = (this.currentLanguage !== 'ar' && this.currentLanguage !== 'fa' && (this.shiftState === ShiftState.On || this.shiftState === ShiftState.CapsLock))
          ? key.shiftValue ?? key.mainValue
          : key.mainValue;
        keyboardController.insertText(text);
        this.onTextTyped(text);
        if (this.shiftState === ShiftState.On) {
          this.shiftState = ShiftState.Off;
        }
        break;
      case KeyAction.Space:
        keyboardController.insertText(' ');
        this.onBoundaryTyped(' ');
        break;
      case KeyAction.Enter:
        keyboardController.sendEnterKey();
        this.onBoundaryTyped('\n');
        break;
      case KeyAction.Backspace:
        keyboardController.deleteForward(1);
        this.onBackspaceTyped();
        break;
      case KeyAction.Shift:
        const now = Date.now();
        if (this.shiftState === ShiftState.CapsLock) {
          this.shiftState = ShiftState.Off;
          this.lastShiftTapTs = now;
          break;
        }
        if (now - this.lastShiftTapTs < 400) {
          this.shiftState = ShiftState.CapsLock;
          this.lastShiftTapTs = 0;
          break;
        }
        this.shiftState = (this.shiftState === ShiftState.Off) ?
          ShiftState.On : ShiftState.Off;
        this.lastShiftTapTs = now;
        break;
      case KeyAction.SwitchAlphabet:
      case KeyAction.SwitchSymbols:
        this.keyboardLayout = (this.keyboardLayout === KeyboardLayout.Alphabet) ?
          KeyboardLayout.Symbols1 : KeyboardLayout.Alphabet;
        break;
      case KeyAction.SwitchSymbolsAlt:
        this.keyboardLayout = KeyboardLayout.Symbols2;
        break;
    }
  }

  handleClipboardClick(): void {
    this.resetInactivityTimer();

    if (this.isRecording) {
      this.isRecording = false;
      console.info('Pisanie g╨Х╙оosem przerwane przez otwarcie schowka.');
    }

    // Get the latest item from clipboard history and paste it directly
    if (this.clipboardHistory.length > 0) {
      const latestItem = this.clipboardHistory[0];
      keyboardController.insertText(latestItem);
      this.onTextTyped(latestItem);
    }

    // Close any open panels
    this.showEmojiPanel = false;
  }

  handleSwipe(direction: LayoutSwipeDirection): void {
    if (this.availableLanguages.length <= 1) {
      console.warn('OpenBoard Keyboard: Only one language enabled, cannot switch.');
      return;
    }

    let currentIndex = this.availableLanguages.indexOf(this.currentLanguage);

    if (direction === LayoutSwipeDirection.Right) {
      currentIndex = (currentIndex - 1 + this.availableLanguages.length) % this.availableLanguages.length;
    } else {
      currentIndex = (currentIndex + 1) % this.availableLanguages.length;
    }

    this.currentLanguage = this.availableLanguages[currentIndex];
    console.info('OpenBoard Keyboard: Switched to language:', this.currentLanguage);
  }

  private updateSuggestions(): void {
    try {
      const list = predictionModel.predict(this.currentLanguage, this.previousWord, this.currentWord, 3);
      this.suggestions = [list[0] ?? '', list[1] ?? '', list[2] ?? ''];
    } catch (e) {
      console.warn('Prediction model error:', e);
      this.suggestions = ['', '', ''];
    }
  }

  private isBoundaryChar(ch: string): boolean {
    if (!ch) return false;
    const boundaries = [' ', '\n', ',', '.', '╨и╥в', '╨и╥╣', '!', '?', ';', ':', '/', '\\', '-', '_', '"', "'", '(', ')', '[', ']', '<', '>'];
    return boundaries.indexOf(ch) >= 0;
  }

  private onTextTyped(text: string): void {
    if (!text) return;
    if (this.isBoundaryChar(text)) {
      this.onBoundaryTyped(text);
      return;
    }
    this.currentWord = this.currentWord + text;
    this.updateSuggestions();
    this.resetInactivityTimer();
  }

  private onBoundaryTyped(_: string): void {
    if (this.currentWord) {
      predictionModel.recordWord(this.currentLanguage, this.previousWord, this.currentWord);
      this.previousWord = this.currentWord;
      this.currentWord = '';
    }
    this.updateSuggestions();
    this.resetInactivityTimer();
  }

  private onBackspaceTyped(): void {
    if (this.currentWord && this.currentWord.length > 0) {
      this.currentWord = this.currentWord.substring(0, this.currentWord.length - 1);
      this.updateSuggestions();
      this.resetInactivityTimer();
    }
  }

  private pickSuggestion(word: string): void {
    this.resetInactivityTimer();
    keyboardController.deleteForward(this.currentWord.length);
    keyboardController.insertText(word);
    keyboardController.insertText(' ');

    this.onBoundaryTyped(' ');
    this.previousWord = word;
    this.currentWord = '';
    this.updateSuggestions();
  }

  private getScreenWidthVp(): number {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      return displayInfo.width / 3;
    } catch (e) {
      console.error('Failed to get screen width:', e);
      return 360;
    }
  }

  // Build different toolbar variants using @Builder
  @Builder
  buildStandardToolbar() {
    Row({ space: 3 }) {
      // IKONA ZAMKNIJ
      Column() {
        Image($r('app.media.close_icon'))
          .width(18)
          .height(18)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(OpenBoardTheme.specialKey)
      .onClick(() => { keyboardController.hideKeyboard(); })

      // SUGESTIE
      Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        Row({ space: 0 }) {
          ForEach(this.suggestions, (suggestion: string, index: number) => {
            Column() {
              Text(suggestion)
                .fontSize(16)
                .fontWeight(500)
                .fontColor(OpenBoardTheme.primaryText)
                .textAlign(TextAlign.Center)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .layoutWeight(1)
            .onClick(() => {
              if (suggestion) this.pickSuggestion(suggestion);
            })

            if (index < 2) {
              Text(' | ')
                .fontSize(16)
                .fontWeight(500)
                .fontColor(OpenBoardTheme.secondaryText)
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)

      // MIKROFON
      Column() {
        Image($r('app.media.mic_icon'))
          .width(20)
          .height(20)
          .fillColor(this.isRecording ? OpenBoardTheme.accent : OpenBoardTheme.primaryText)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(this.isRecording ? OpenBoardTheme.accent : OpenBoardTheme.specialKey)
      .onClick(() => {
        this.isRecording = !this.isRecording;
        this.showEmojiPanel = false;
        this.resetInactivityTimer();
      })
    }
  }

  @Builder
  buildPreTypingToolbar() {
    Row({ space: 3 }) {
      // IKONA ZAMKNIJ
      Column() {
        Image($r('app.media.close_icon'))
          .width(18)
          .height(18)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(OpenBoardTheme.specialKey)
      .onClick(() => { keyboardController.hideKeyboard(); })

      // IKONA SCHOWKA
      Column() {
        Image($r('app.media.clipboard_icon'))
          .width(20)
          .height(20)
          .fillColor(OpenBoardTheme.primaryText)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(OpenBoardTheme.specialKey)
      .onClick(() => { this.handleClipboardClick(); })

      // PUSTE MIEJSCE
      Flex().layoutWeight(1)

      // MIKROFON
      Column() {
        Image($r('app.media.mic_icon'))
          .width(20)
          .height(20)
          .fillColor(this.isRecording ? OpenBoardTheme.accent : OpenBoardTheme.primaryText)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(this.isRecording ? OpenBoardTheme.accent : OpenBoardTheme.specialKey)
      .onClick(() => {
        this.isRecording = !this.isRecording;
        this.showEmojiPanel = false;
        this.resetInactivityTimer();
      })
    }
  }

  @Builder
  buildEmojiToolbar() {
    Row({ space: 3 }) {
      // PRZYCISK POWROTU DO KLAWIATURY
      Column() {
        Text('╨▓╥▓╥░')
          .fontSize(20)
          .fontWeight(500)
          .fontColor(OpenBoardTheme.primaryText)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(OpenBoardTheme.specialKey)
      .onClick(() => {
        this.showEmojiPanel = false;
        this.resetInactivityTimer();
      })

      // PUSTE MIEJSCE
      Flex().layoutWeight(1)

      // PUSTE MIEJSCE
      Flex().layoutWeight(1)
    }
  }

  @Builder
  buildVoiceToolbar() {
    Row({ space: 3 }) {
      // IKONA ZAMKNIJ
      Column() {
        Image($r('app.media.close_icon'))
          .width(18)
          .height(18)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(17)
      .backgroundColor(OpenBoardTheme.specialKey)
      .onClick(() => { keyboardController.hideKeyboard(); })

      // STATUS NAGRYWANIA G╨Х╥ТOSU
      Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        Row({ space: 6 }) {
          Image($r('app.media.mic_icon'))
            .width(18)
            .height(18)
            .fillColor(OpenBoardTheme.primaryText)

          Text(getVoiceDictationStatus(this.currentLanguage))
            .fontSize(16)
            .fontWeight(500)
            .fontColor(OpenBoardTheme.primaryText)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
    }
  }

  build() {
    Stack() {
      Column() {}
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
      .backgroundColor(OpenBoardTheme.background)
      .animation({ duration: 200 })

      Column() {
        // G╨Х╥Т╨УтАЬWNY PASEK ZADA╨Х╥У - WARUNKOWY RENDEROWANIE
        Row({ space: 3 }) {
          if (this.isRecording) {
            // Toolbar when typing with voice
            this.buildVoiceToolbar()
          } else if (this.showEmojiPanel) {
            // Toolbar when in emoji tab
            this.buildEmojiToolbar()
          } else if (this.showPreTypingToolbar && this.currentWord === '') {
            // Toolbar before starting to type and after 5 sec of not typing
            this.buildPreTypingToolbar()
          } else {
            // Standard toolbar when typing
            this.buildStandardToolbar()
          }
        }
        .width('100%')
        .height(46)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(OpenBoardTheme.surface)
        .borderRadius(12)
        .border({ width: 1, color: OpenBoardTheme.divider })
        .shadow({ radius: 8, color: '#40000000', offsetY: 2 })

        // G╨Х╥Т╨УтАЬWNA TRE╨Х╥б╨Ф╥╢
        if (!this.showEmojiPanel) {
          // G╨Х╙о╨У╤Цwna klawiatura
          Column({ space: 1 }) {
            ForEach(this.getCurrentLayout(), (row: KeyData[]) => {
              Row() {
                ForEach(row, (key: KeyData) => {
                  if (key.action === KeyAction.Spacer) {
                    Flex().layoutWeight(key.flex)
                  } else {
                    KeyView({
                      keyData: key,
                      shiftState: this.shiftState,
                      currentLanguage: this.currentLanguage,
                      availableLanguages: this.availableLanguages,
                      enterKeyLabel: this.enterKeyLabel,
                      onKeyPress: (k: KeyData): void => this.handleKeyPress(k),
                      onKeyLongPress: (k: KeyData, p: Position): void => this.handleLongPress(k, p),
                      onKeyContinuousPressStart: (): void => this.handleRapidDeleteStart(),
                      onKeyContinuousPressEnd: (): void => this.handleRapidDeleteEnd(),
                      onSwipe: key.action === KeyAction.Space ? (direction: LayoutSwipeDirection): void => this.handleSwipe(direction) : undefined
                    })
                      .layoutWeight(key.flex)
                  }
                })
              }
              .width('100%')
              .layoutWeight(1)
            })
          }
          .layoutWeight(1)
          .padding({ left: 2, right: 2, bottom: 2 })
        } else {
          // Panel Emoji
          Column({ space: 10 }) {
            // Kategorie Emoji
            Scroll() {
              Row() {
                ForEach(EMOJI_CATEGORIES, (cat: string) => {
                  Text(cat)
                    .fontSize(14)
                    .fontWeight(500)
                    .fontColor(this.emojiCategory === cat ? OpenBoardTheme.accent : OpenBoardTheme.secondaryText)
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .backgroundColor(this.emojiCategory === cat ? OpenBoardTheme.surface : OpenBoardTheme.background)
                    .borderRadius(20)
                    .onClick(() => { this.emojiCategory = cat; this.resetInactivityTimer(); })
                })
              }
              .padding({ left: 8, right: 8 })
            }

            // Emoji
            Scroll(this.emojiScroller) {
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
                ForEach(this.getEmojiList(this.emojiCategory), (emoji: string) => {
                  Text(emoji)
                    .fontSize(28)
                    .textAlign(TextAlign.Center)
                    .width('11%')
                    .height(46)
                    .onClick(() => {
                      keyboardController.insertText(emoji);
                      this.onTextTyped(emoji);
                      this.resetInactivityTimer();
                    })
                })
              }
              .width('100%')
              .padding({ left: 8, right: 8 })
            }
            .scrollable(ScrollDirection.Vertical)
            .scrollBar(BarState.On)
            .onScrollFrameBegin((offset: number, state: ScrollState) => {
              return { offsetRemain: offset };
            })
          }
          .layoutWeight(1)
          .padding({ left: 2, right: 2, bottom: 2 })
        }
      }
      .alignSelf(ItemAlign.End)
      .backgroundColor(OpenBoardTheme.background)

      // Popupy
      if (this.longPressInfo) {
        KeyPopup({ info: this.longPressInfo, hoveredChar: this.hoveredChar, keyWidth: this.popupKeyWidth })
          .position({ x: this.popupPosition.x, y: this.popupPosition.y })
          .zIndex(200)
      }

      if (this.singleCharPopupInfo) {
        SingleKeyPopup({ char: this.singleCharPopupInfo.char })
          .position({ x: this.singleCharPopupInfo.position.x - 25, y: this.singleCharPopupInfo.position.y - 70 })
          .zIndex(150)
      }

      if (this.languageIndicatorOpacity > 0) {
        LanguageIndicator({ languageName: getLanguageName(this.currentLanguage) })
          .opacity(this.languageIndicatorOpacity)
          .position({ x: (this.getScreenWidthVp() / 2) - 100, y: 150 })
          .zIndex(250)
      }
    }
    .width('100%')
    .height('100%')
  }

  getCurrentLayout(): KeyData[][] {
    const insertEmojiKey = (layout: KeyData[][] | undefined): KeyData[][] => {
      if (!layout || layout.length < 4) return layout || [];
      const lastRow = layout[layout.length - 1].slice();
      const commaIndex = lastRow.findIndex(k => k.mainValue === ',');
      if (commaIndex !== -1 && lastRow[commaIndex + 1]?.action === KeyAction.Space) {
        lastRow.splice(commaIndex + 1, 0, EMOJI_KEY_DATA);
        const spaceKey = lastRow[commaIndex + 2];
        if (spaceKey) {
          spaceKey.flex = Math.max(spaceKey.flex - EMOJI_KEY_DATA.flex + 0.5, 3.5);
        }
        const newLayout = layout.slice(0, layout.length - 1);
        newLayout.push(lastRow);
        return newLayout;
      }
      return layout;
    };

    switch (this.keyboardLayout) {
      case KeyboardLayout.Alphabet:
        switch (this.currentLanguage) {
          case 'ar': return arabicLayout;
          case 'en': return insertEmojiKey(englishLayout);
          case 'it': return insertEmojiKey(italianLayout);
          case 'pl': return insertEmojiKey(polishLayout);
          case 'fa': return persianLayout;
          default: return insertEmojiKey(englishLayout);
        }
      case KeyboardLayout.Symbols1: return symbolsLayout1;
      case KeyboardLayout.Symbols2: return symbolsLayout2;
      default: return insertEmojiKey(englishLayout);
    }
  }

  private getEmojiList(category: string): string[] {
    switch (category) {
      case 'Smileys & Emotion':
        // Emocje, gesty, bu┼║ki, serduszka
        return ['ЁЯША','ЁЯШБ','ЁЯШВ','ЁЯдг','ЁЯШГ','ЁЯШД','ЁЯШЕ','ЁЯШЖ','ЁЯШЙ','ЁЯШК','ЁЯШЛ','ЁЯШО','ЁЯе░','ЁЯШН','ЁЯШШ','ЁЯШЧ','ЁЯШЩ','ЁЯШЪ','ЁЯе▓','ЁЯе│','ЁЯдй','ЁЯдЧ','ЁЯдФ','ЁЯди','ЁЯШР','ЁЯШ╢','ЁЯШП','ЁЯШТ','ЁЯЩД','ЁЯШм','ЁЯде','ЁЯШЯ','ЁЯШФ','ЁЯШе','ЁЯдд','ЁЯШл','ЁЯШй','ЁЯе║','ЁЯШн','ЁЯШд','ЁЯШо','ЁЯШ▒','ЁЯШ│','ЁЯдп','ЁЯе╡','ЁЯе╢','ЁЯШ┤','ЁЯШ╡','ЁЯШ╖','ЁЯдХ','ЁЯдв','ЁЯдо','ЁЯдз','ЁЯШЗ','ЁЯШИ','ЁЯС┐','ЁЯС╣','ЁЯС║','ЁЯТА','ЁЯС╗','ЁЯС╜','ЁЯдЦ','ЁЯТй','ЁЯШ║','ЁЯШ╕','ЁЯШ╣','ЁЯШ╗','ЁЯШ╝','ЁЯШ╜','ЁЯШ╛','ЁЯШ┐','ЁЯЩА','ЁЯл╢','ЁЯСН','ЁЯСО','тЬК','ЁЯСК','ЁЯдЭ','ЁЯдЮ','тЬМя╕П','ЁЯл░','ЁЯдЯ','ЁЯдШ','ЁЯСМ','ЁЯдМ','ЁЯдП','ЁЯСИ','ЁЯСЙ','ЁЯСЖ','ЁЯСЗ','тШЭя╕П','тЬЛ','ЁЯдЪ','ЁЯЦРя╕П','S','ЁЯТк','ЁЯЩП','тЬНя╕П','ЁЯТЕ','ЁЯСВ','ЁЯСГ','ЁЯСБя╕П','ЁЯза','ЁЯж╖','ЁЯж┤','ЁЯЧгя╕П','ЁЯСд','ЁЯСе','ЁЯлВ'];
      case 'People':
        // Ludzie, cz─Щ┼Ыci cia┼Вa, zawody, rodziny
        return ['ЁЯС╢','ЁЯСз','ЁЯзТ','ЁЯСж','ЁЯСй','ЁЯзС','ЁЯСи','ЁЯС╡','ЁЯзУ','ЁЯС┤','ЁЯС▒тАНтЩАя╕П','ЁЯС▒','ЁЯС▒тАНтЩВя╕П','ЁЯСотАНтЩАя╕П','ЁЯСо','ЁЯСотАНтЩВя╕П','ЁЯС╖тАНтЩАя╕П','ЁЯС╖','ЁЯС╖тАНтЩВя╕П','ЁЯзСтАНтЪХя╕П','ЁЯСитАНтЪХя╕П','ЁЯСйтАНтЪХя╕П','ЁЯзСтАНЁЯОУ','ЁЯСитАНЁЯОУ','ЁЯСйтАНЁЯОУ','ЁЯзСтАНЁЯПл','ЁЯСитАНЁЯПл','ЁЯСйтАНЁЯПл','ЁЯзСтАНтЪЦя╕П','ЁЯСитАНтЪЦя╕П','ЁЯСйтАНтЪЦя╕П','ЁЯзСтАНЁЯМ╛','ЁЯСитАНЁЯМ╛','ЁЯСйтАНЁЯМ╛','ЁЯзСтАНЁЯН│','ЁЯСитАНЁЯН│','ЁЯСйтАНЁЯН│','ЁЯзСтАНЁЯФз','ЁЯСитАНЁЯФз','ЁЯСйтАНЁЯФз','ЁЯзСтАНЁЯПн','ЁЯСитАНЁЯПн','ЁЯСйтАНЁЯПн','ЁЯзСтАНЁЯТ╝','ЁЯСитАНЁЯТ╝','ЁЯСйтАНЁЯТ╝','ЁЯзСтАНЁЯФм','ЁЯСитАНЁЯФм','ЁЯСйтАНЁЯФм','ЁЯзСтАНЁЯТ╗','ЁЯСитАНЁЯТ╗','ЁЯСйтАНЁЯТ╗','ЁЯзСтАНЁЯОд','ЁЯСитАНЁЯОд','ЁЯСйтАНЁЯОд','ЁЯзСтАНЁЯОи','ЁЯСитАНЁЯОи','ЁЯСйтАНЁЯОи','ЁЯзСтАНтЬИя╕П','ЁЯСитАНтЬИя╕П','ЁЯСйтАНтЬИя╕П','ЁЯзСтАНЁЯЪА','ЁЯСитАНЁЯЪА','ЁЯСйтАНЁЯЪА','ЁЯзСтАНЁЯЪТ','ЁЯСитАНЁЯЪТ','ЁЯСйтАНЁЯЪТ','ЁЯТВтАНтЩАя╕П','ЁЯТВ','ЁЯТВтАНтЩВя╕П','ЁЯХ╡я╕ПтАНтЩАя╕П','ЁЯХ╡я╕П','ЁЯХ╡я╕ПтАНтЩВя╕П','ЁЯе╖','ЁЯд╡тАНтЩАя╕П','ЁЯд╡','ЁЯд╡тАНтЩВя╕П','ЁЯС░тАНтЩАя╕П','ЁЯС░','ЁЯС░тАНтЩВя╕П','ЁЯд░','ЁЯд▒','ЁЯзСтАНЁЯН╝','ЁЯСитАНЁЯН╝','ЁЯСйтАНЁЯН╝','ЁЯС╝','ЁЯОЕ','ЁЯд╢','ЁЯзСтАНЁЯОД','ЁЯж╕тАНтЩАя╕П','ЁЯж╕','ЁЯж╕тАНтЩВя╕П','ЁЯж╣тАНтЩАя╕П','ЁЯж╣','ЁЯж╣тАНтЩВя╕П','ЁЯзЩтАНтЩАя╕П','ЁЯзЩ','ЁЯзЩтАНтЩВя╕П','ЁЯзЪтАНтЩАя╕П','ЁЯзЪ','ЁЯзЪтАНтЩВя╕П','ЁЯзЫтАНтЩАя╕П','ЁЯзЫ','ЁЯзЫтАНтЩВя╕П','ЁЯзЬтАНтЩАя╕П','ЁЯзЬ','ЁЯзЬтАНтЩВя╕П','ЁЯзЭтАНтЩАя╕П','ЁЯзЭ','ЁЯзЭтАНтЩВя╕П','ЁЯзЮтАНтЩАя╕П','ЁЯзЮ','ЁЯзЮтАНтЩВя╕П','ЁЯзЯтАНтЩАя╕П','ЁЯзЯ','ЁЯзЯтАНтЩВя╕П','ЁЯЪ╢тАНтЩАя╕П','ЁЯЪ╢','ЁЯЪ╢тАНтЩВя╕П','ЁЯПГтАНтЩАя╕П','ЁЯПГ','ЁЯПГтАНтЩВя╕П','ЁЯХ║','ЁЯТГ','ЁЯзСтАНЁЯж╜','ЁЯСитАНЁЯж╜','ЁЯСйтАНЁЯж╜','ЁЯзСтАНЁЯж╝','ЁЯСитАНЁЯж╝','ЁЯСйтАНЁЯж╝','ЁЯзНтАНтЩАя╕П','ЁЯзН','ЁЯзНтАНтЩВя╕П',' sitting','ЁЯзОтАНтЩАя╕П','ЁЯзО','ЁЯзОтАНтЩВя╕П',' kneeling','ЁЯзСтАНЁЯжп','ЁЯСитАНЁЯжп','ЁЯСйтАНЁЯжп','ЁЯзСтАН standing','ЁЯСитАН standing','ЁЯСйтАН standing','ЁЯСйтАНтЭдя╕ПтАНЁЯСи','ЁЯСитАНтЭдя╕ПтАНЁЯСи','ЁЯСйтАНтЭдя╕ПтАНЁЯСй','familia','ЁЯТЛ','ЁЯТШ','ЁЯТЭ','ЁЯТЦ','ЁЯТЧ','ЁЯТУ','ЁЯТЮ','ЁЯТХ','ЁЯзб','ЁЯТЫ','ЁЯТЪ','ЁЯТЩ','ЁЯТЬ','ЁЯдО','ЁЯЦд','ЁЯдН','ЁЯТп','ЁЯТв','ЁЯТе','ЁЯТл','ЁЯТж','ЁЯТи','ЁЯТм','ЁЯСБя╕ПтАНЁЯЧия╕П','ЁЯТн','ЁЯТб','ЁЯФе'];
      case 'Animals & Nature':
        // Zwierz─Щta, ro┼Ыliny, pogoda, krajobrazy
        return ['ЁЯР╢','ЁЯР▒','ЁЯРн','ЁЯР╣','ЁЯР░','ЁЯжК','ЁЯР╗','ЁЯР╝','ЁЯРи','ЁЯРп','ЁЯжБ','ЁЯРо','ЁЯР╖','ЁЯР╜','ЁЯР╕','ЁЯР╡','ЁЯРТ','ЁЯжН','ЁЯРФ','ЁЯРз','ЁЯРж','ЁЯРд','ЁЯРг','ЁЯРе','ЁЯжЖ','ЁЯжв','ЁЯжЕ','ЁЯжЙ','ЁЯжй',' peacock',' parrot','ЁЯХКя╕П','ЁЯР║','ЁЯРЧ','ЁЯР┤','ЁЯжУ','ЁЯжМ','ЁЯжП',' hippopotamus','ЁЯжТ','ЁЯРк','ЁЯРл','ЁЯРШ','ЁЯже','ЁЯжж','ЁЯжи','ЁЯжФ','ЁЯР┐я╕П','ЁЯРБ','ЁЯРА','ЁЯРЗ','ЁЯРИ','ЁЯРЙ','ЁЯР▓','ЁЯРК','ЁЯРв','ЁЯРН','ЁЯжО','ЁЯжЦ','ЁЯжХ','ЁЯРЛ','ЁЯР│','ЁЯРм','ЁЯРа','ЁЯРб','ЁЯжИ','ЁЯРЩ','ЁЯжС','ЁЯжР','ЁЯжА','ЁЯжЮ',' snail','ЁЯжЛ','ЁЯРЫ','ЁЯРЬ','ЁЯРЭ','ЁЯРЮ','ЁЯжЧ','ЁЯХ╖я╕П','ЁЯжВ','ЁЯжа','ЁЯТР','ЁЯМ╕','ЁЯМ╝','ЁЯМ╗','ЁЯМ╖','ЁЯМ╣','ЁЯеА','ЁЯМ║','ЁЯк┤','ЁЯМ▓','ЁЯМ│','ЁЯМ┤','ЁЯМ╡','ЁЯМ╛','ЁЯМ┐','тШШя╕П','ЁЯНА','ЁЯНБ','ЁЯНВ','ЁЯНГ','ЁЯНД','ЁЯМ░','ЁЯМО','ЁЯМН','ЁЯМП','ЁЯМС','ЁЯМХ','ЁЯМУ','ЁЯМФ','ЁЯМЦ','ЁЯМЧ','ЁЯМШ','ЁЯМЩ','тнР','ЁЯМЯ','тЬи','тЪб','ЁЯФе','тШАя╕П','ЁЯМдя╕П','тЫЕ','ЁЯМея╕П','ЁЯМжя╕П','тШБя╕П','ЁЯМия╕П','ЁЯМзя╕П','тЫИя╕П','ЁЯМйя╕П','тЭДя╕П','тЫД','ЁЯМмя╕П','ЁЯТи','ЁЯМкя╕П','ЁЯМА','ЁЯМИ','ЁЯМК','ЁЯТз','тШФ','тШВя╕П','ЁЯТж'];
      case 'Food & Drink':
        // Owoce, warzywa, dania, s┼Вodycze, napoje
        return ['ЁЯНО','ЁЯНП','ЁЯНР','ЁЯНК','ЁЯНЛ','ЁЯНМ','ЁЯНЙ','ЁЯНЗ','ЁЯНУ','ЁЯлР','ЁЯНТ','ЁЯНС','ЁЯен','ЁЯНН','ЁЯее','ЁЯеЭ','ЁЯНЕ','ЁЯНЖ','ЁЯеХ','ЁЯМ╜','ЁЯМ╢я╕П','ЁЯеТ','ЁЯеж','ЁЯлС','ЁЯзЕ','ЁЯзД','ЁЯеФ','ЁЯНа','ЁЯеР','ЁЯНЮ','ЁЯеЦ','ЁЯеи','ЁЯеп','ЁЯеЮ','ЁЯзЗ','ЁЯзА','ЁЯей','ЁЯНЧ','ЁЯНЦ','ЁЯеУ','ЁЯНФ','ЁЯНЯ','ЁЯНХ','ЁЯМн','ЁЯек','ЁЯМо','ЁЯМп','ЁЯеЩ','ЁЯеЪ','ЁЯН│','ЁЯеШ','ЁЯН▓','ЁЯег','ЁЯеЧ',' popcorn','ЁЯзИ','ЁЯзВ','ЁЯел','ЁЯН▒','ЁЯНЩ','ЁЯНЪ','ЁЯНШ','ЁЯНе','ЁЯНг','ЁЯНд','ЁЯНЬ','ЁЯНЭ','ЁЯНЫ','ЁЯНа','ЁЯНв','ЁЯНб','ЁЯеЯ','ЁЯеа','ЁЯеб','ЁЯНж','ЁЯНз','ЁЯНи','ЁЯНй','ЁЯНк','ЁЯОВ','ЁЯН░','ЁЯзБ','ЁЯез','ЁЯНл','ЁЯНм','ЁЯНн','ЁЯНо','ЁЯНп','ЁЯН╝','ЁЯеЫ','тШХ','ЁЯН╡','ЁЯед','ЁЯзЛ','ЁЯлЧ','ЁЯН║','ЁЯН╗','ЁЯН╖','ЁЯеВ','ЁЯН╛','ЁЯеГ','ЁЯН╕','ЁЯН╣','ЁЯН╢','ЁЯзК','ЁЯег','ЁЯН┤','ЁЯеД','ЁЯев','ЁЯеб','ЁЯзз'];
      case 'Activity & Event':
        // Sport, hobby, muzyka, ┼Ыwi─Щta, wydarzenia
        return ['тЪ╜','ЁЯПА','ЁЯПИ','тЪ╛','ЁЯеО','ЁЯО╛','ЁЯПР','ЁЯПЙ','ЁЯО▒','ЁЯПУ',' badminton','ЁЯеК','ЁЯеЛ','тЫ╕я╕П','ЁЯО┐','ЁЯПВ','тЫ╖я╕П','ЁЯП╣','ЁЯОп','ЁЯО│','тЫ│','ЁЯОг','ЁЯПКтАНтЩВя╕П','ЁЯЪ┤тАНтЩВя╕П','ЁЯПГтАНтЩВя╕П','ЁЯЪ╢тАНтЩВя╕П','ЁЯй░','ЁЯОд','ЁЯОз','ЁЯО╝','ЁЯО╣','ЁЯеБ','ЁЯО╕','ЁЯО║','ЁЯО╗','ЁЯОм','ЁЯОн','ЁЯЦ╝я╕П','ЁЯОи','ЁЯз╡','ЁЯз╢','ЁЯО▓','тЩЯя╕П','ЁЯзй','ЁЯз╕','ЁЯОо','ЁЯХ╣я╕П','ЁЯО░','ЁЯОб','ЁЯОв','ЁЯОа','ЁЯОК','ЁЯОЙ','ЁЯОБ','ЁЯОИ','ЁЯОА','ЁЯОЧя╕П','ЁЯОЯя╕П','ЁЯОл','ЁЯОЦя╕П','ЁЯПЖ','ЁЯПЕ','ЁЯеЗ','ЁЯеИ','ЁЯеЙ','ЁЯФФ','ЁЯОД','ЁЯОЕ','ЁЯОГ','ЁЯС╗','ЁЯОВ','ЁЯТН','ЁЯТО','ЁЯТ░','ЁЯТ▓','ЁЯТ╕','ЁЯТ╡','ЁЯТ╢','ЁЯТ╖','ЁЯТ┤','ЁЯТ│','ЁЯз╛','ЁЯФЧ','ЁЯФТ','ЁЯФУ','ЁЯФС'];
      case 'Travel & Places':
        // Pojazdy, miejsca, budynki
        return ['ЁЯЪЧ','ЁЯЪХ','ЁЯЪЩ','ЁЯЪМ','ЁЯЪО','ЁЯПОя╕П','ЁЯЪУ','ЁЯЪС','ЁЯЪТ','ЁЯЪР','ЁЯЪЪ','ЁЯЪЫ','ЁЯЪЬ','ЁЯПНя╕П','ЁЯЫ╡','ЁЯЪ▓','ЁЯЫ┤','ЁЯЪи','тЫ╜','ЁЯЫгя╕П','ЁЯЫдя╕П','ЁЯЪП','ЁЯЪж','ЁЯЪе','ЁЯЪз','anchor','ЁЯЪв','тЫ┤я╕П','ЁЯЪд','ЁЯЫея╕П','ЁЯЫ│я╕П','ЁЯЪА','ЁЯЫ╕','ЁЯЪБ','ЁЯЪВ','ЁЯЪГ','ЁЯЪЛ','ЁЯЪМ','ЁЯЪЖ','ЁЯЪЗ','ЁЯЪК','ЁЯЪЙ','тЬИя╕П','ЁЯЫл','ЁЯЫм','ЁЯТ║','ЁЯПи','motel','house','ЁЯПа','ЁЯПб','ЁЯПШя╕П','ЁЯПЪя╕П','ЁЯПЧя╕П','ЁЯПв','ЁЯПн','ЁЯПм','ЁЯПг','щГ╡','ЁЯПж','ЁЯПе','ЁЯПл','ЁЯПд','тЫк','ЁЯХМ','ЁЯХН','ЁЯХЛ',' fountain','тЫ▓','ЁЯЧ╝',' statue of liberty','ЁЯЧ╛','ЁЯМЛ',' mount fuji','ЁЯЧ╗',' at the sea','ЁЯПЦя╕П','desert','island','тЫ║','ЁЯМГ','ЁЯПЩя╕П','ЁЯМД','ЁЯМЕ','ЁЯМЗ','ЁЯМЖ','ЁЯМЙ',' Milky Way','ЁЯМа','ЁЯОЗ','ЁЯОЖ'];
      case 'Objects':
        // Przedmioty, narz─Щdzia, ubrania, elektronika
        return ['тМЪ','ЁЯУ▒','ЁЯТ╗','тМия╕П','ЁЯЦия╕П','ЁЯЦ▒я╕П','ЁЯУ╖','ЁЯУ╕','ЁЯУ╣','ЁЯУ╝','ЁЯТ┐','ЁЯУА','ЁЯУ╗','ЁЯУ║','ЁЯУЮ','ЁЯУа','ЁЯФЛ','ЁЯФМ','ЁЯТб','ЁЯФж','ЁЯХпя╕П','ЁЯЧСя╕П','ЁЯЫТ','тЬЙя╕П','ЁЯУз','ЁЯУй','ЁЯУи','ЁЯУд','ЁЯУе','ЁЯУж','ЁЯУл','ЁЯУк','ЁЯУм','ЁЯУн','ЁЯУо','ЁЯУЬ','ЁЯУГ','ЁЯУД','ЁЯУС','ЁЯУЕ','ЁЯЧУя╕П','ЁЯУЗ','ЁЯУИ','ЁЯУЙ','ЁЯУК','ЁЯУЛ','ЁЯУМ','ЁЯУН','ЁЯУО','ЁЯЦЗя╕П','ЁЯУП','ЁЯУР','тЬВя╕П','ЁЯкЪ','ЁЯФи','тЫПя╕П','ЁЯкУ','ЁЯФк','ЁЯФл','ЁЯй║','ЁЯзк','ЁЯМбя╕П','ЁЯТЙ','ЁЯТК','ЁЯй╣','ЁЯЪк','ЁЯкС','ЁЯЫЛя╕П','ЁЯЫПя╕П','ЁЯЫА','ЁЯз╝','ЁЯз╜','ЁЯз║','ЁЯЪ╜','ЁЯЪ┐','ЁЯЫБ','ЁЯка','ЁЯз┤','ЁЯСЪ','ЁЯСХ','ЁЯСЦ','ЁЯСФ','ЁЯСЧ','ЁЯСЩ','ЁЯСШ','ЁЯе╗','ЁЯй▒','ЁЯй▓','ЁЯй│','ЁЯзе','ЁЯе╝','ЁЯзг','ЁЯзд','ЁЯзв','ЁЯСТ','ЁЯОУ','ЁЯСС','ЁЯТН','ЁЯТО','ЁЯТД','ЁЯТЕ','ЁЯко','ЁЯкТ','ЁЯке','ЁЯкг','ЁЯкд','ЁЯкЯ','ЁЯкЬ','ЁЯкЮ','ЁЯкЪ','ЁЯкЫ','ЁЯЫая╕П','тЪЩя╕П','ЁЯз▒','тЫУя╕П','ЁЯФЧ','ЁЯУП','ЁЯзо'];
      case 'Symbols':
        // Znaki, strza┼Вki, cyfry, emotikony tekstowe
        return ['тЭдя╕П','ЁЯзб','ЁЯТЫ','ЁЯТЪ','ЁЯТЩ','ЁЯТЬ','ЁЯЦд','ЁЯдН','ЁЯдО','ЁЯТФ','тЭЧя╕П','тЭУ','тА╝я╕П','тБЙя╕П','тЬЕ','тЭМ','тЬФя╕П','тЬЦя╕П','тЮХ','тЮЦ','тЮЧ','тЩ╛я╕П','┬йя╕П','┬оя╕П','тДвя╕П','тДа','┬оя╕П','тДвя╕П','┬йя╕П','┬оя╕П','тДвя╕П','тДа','#я╕ПтГг','*я╕ПтГг','0я╕ПтГг','1я╕ПтГг','2я╕ПтГг','3я╕ПтГг','4я╕ПтГг','5я╕ПтГг','6я╕ПтГг','7я╕ПтГг','8я╕ПтГг','9я╕ПтГг','ЁЯФЯ','тмЖя╕П','тмЗя╕П','тмЕя╕П','тЮбя╕П','тЖЦя╕П','тЖЧя╕П','тЖШя╕П','тЖЩя╕П','тЖХя╕П','тЖФя╕П','тЖйя╕П','тЖкя╕П','тд┤я╕П','тд╡я╕П','ЁЯФД','тЧАя╕П','тЦ╢я╕П','ЁЯФ╝','ЁЯФ╜','тППя╕П','тЮ┐','тЩ╗я╕П','тЪЬя╕П','ЁЯФ▒','тЪая╕П','тЫФ','ЁЯЪл','ЁЯЪн','ЁЯЪ│','ЁЯЪ▒','ЁЯЪ╖','ЁЯУ╡','ЁЯФЮ',' P','ЁЯЕ┐я╕П','ЁЯЪ╕','ЁЯИп','ЁЯИЪ','ЁЯИ╢','ЁЯИ▓','ЁЯИ╣','ЁЯИ║','ЁЯИ╖я╕П','ЁЯИВя╕П','ЁЯЙС','ЁЯИ┤','ЁЯИ│','уКЧя╕П','уКЩя╕П','тЭМ','тнХ','ЁЯЫС','тЫСя╕П','ЁЯСС','ЁЯФС','ЁЯФФ','ЁЯФХ','ЁЯО╢','ЁЯО╡','тЮХ','тЮЦ','тЮЧ','тЬЦя╕П','тЮ┐','тЬФя╕П','тШСя╕П','тЬЕ','тнХ','тЭМ','ЁЯЫС','тЪая╕П','тЭЧ','тЭУ'];
      case 'Flags':
        // Wybrane flagi
        return ['ЁЯП│я╕П','ЁЯП┤','ЁЯПБ','ЁЯЪй','ЁЯЗжЁЯЗл','ЁЯЗжЁЯЗ╜','ЁЯЗжЁЯЗ▒','ЁЯЗйЁЯЗ┐','ЁЯЗжЁЯЗ╕','ЁЯЗжЁЯЗй','ЁЯЗжЁЯЗ┤','ЁЯЗжЁЯЗо','ЁЯЗжЁЯЗ╢','ЁЯЗжЁЯЗм','ЁЯЗжЁЯЗ╖','ЁЯЗжЁЯЗ▓','ЁЯЗжЁЯЗ╝','ЁЯЗжЁЯЗ║','ЁЯЗжЁЯЗ╣','ЁЯЗжЁЯЗ┐','ЁЯЗзЁЯЗ╕','ЁЯЗзЁЯЗн','ЁЯЗзЁЯЗй','ЁЯЗзЁЯЗз','ЁЯЗзЁЯЗ╛','ЁЯЗзЁЯЗк','ЁЯЗзЁЯЗ┐','ЁЯЗзЁЯЗп','ЁЯЗзЁЯЗ▓','ЁЯЗзЁЯЗ╣','ЁЯЗзЁЯЗ┤','ЁЯЗзЁЯЗж','ЁЯЗзЁЯЗ╝','ЁЯЗзЁЯЗ╖','ЁЯЗоЁЯЗ┤','ЁЯЗ╗ЁЯЗм','ЁЯЗзЁЯЗ│','ЁЯЗзЁЯЗм','ЁЯЗзЁЯЗл','ЁЯЗзЁЯЗо','ЁЯЗ░ЁЯЗн','ЁЯЗиЁЯЗ▓','ЁЯЗиЁЯЗж','ЁЯЗоЁЯЗи','ЁЯЗиЁЯЗ╗','ЁЯЗзЁЯЗ╢','ЁЯЗ░ЁЯЗ╛','ЁЯЗиЁЯЗл','ЁЯЗ╣ЁЯЗй','ЁЯЗиЁЯЗ▒','ЁЯЗиЁЯЗ│','ЁЯЗиЁЯЗ╜','ЁЯЗиЁЯЗи','ЁЯЗиЁЯЗ┤','ЁЯЗ░ЁЯЗ▓','ЁЯЗиЁЯЗм','ЁЯЗиЁЯЗй','ЁЯЗиЁЯЗ░','ЁЯЗиЁЯЗ╖','ЁЯЗнЁЯЗ╖','ЁЯЗиЁЯЗ║','ЁЯЗиЁЯЗ╝','ЁЯЗиЁЯЗ╛','ЁЯЗиЁЯЗ┐','ЁЯЗйЁЯЗ░','ЁЯЗйЁЯЗп','ЁЯЗйЁЯЗ▓','ЁЯЗйЁЯЗ┤','ЁЯЗкЁЯЗи','ЁЯЗкЁЯЗм','ЁЯЗ╕ЁЯЗ╗','ЁЯЗмЁЯЗ╢','ЁЯЗкЁЯЗ╖','ЁЯЗкЁЯЗк','ЁЯЗ╕ЁЯЗ┐','ЁЯЗкЁЯЗ╣','ЁЯЗкЁЯЗ║','ЁЯЗлЁЯЗ░','ЁЯЗлЁЯЗ┤','ЁЯЗлЁЯЗп','ЁЯЗлЁЯЗо','ЁЯЗлЁЯЗ╖','ЁЯЗмЁЯЗл','ЁЯЗ╡ЁЯЗл','ЁЯЗ╣ЁЯЗл','ЁЯЗмЁЯЗж','ЁЯЗмЁЯЗ▓','ЁЯЗмЁЯЗк','ЁЯЗйЁЯЗк','ЁЯЗмЁЯЗн','ЁЯЗмЁЯЗо','ЁЯЗмЁЯЗ╖','ЁЯЗмЁЯЗ▒','ЁЯЗмЁЯЗй','ЁЯЗмЁЯЗ╡','ЁЯЗмЁЯЗ║','ЁЯЗмЁЯЗ╣','ЁЯЗмЁЯЗм','ЁЯЗмЁЯЗ│','ЁЯЗмЁЯЗ╝','ЁЯЗмЁЯЗ╛','ЁЯЗнЁЯЗ╣','ЁЯЗнЁЯЗ│','ЁЯЗнЁЯЗ░','ЁЯЗнЁЯЗ║','ЁЯЗоЁЯЗ╕','ЁЯЗоЁЯЗ│','ЁЯЗоЁЯЗй','ЁЯЗоЁЯЗ╖','ЁЯЗоЁЯЗ╢','ЁЯЗоЁЯЗк','ЁЯЗоЁЯЗ▓','ЁЯЗоЁЯЗ▒','ЁЯЗоЁЯЗ╣','ЁЯЗпЁЯЗ▓','ЁЯЗпЁЯЗ╡','ЁЯЗпЁЯЗк','ЁЯЗпЁЯЗ┤','ЁЯЗ░ЁЯЗ┐','ЁЯЗ░ЁЯЗк','ЁЯЗ░ЁЯЗо','ЁЯЗ╜ЁЯЗ░','ЁЯЗ░ЁЯЗ╝','ЁЯЗ░ЁЯЗм','ЁЯЗ▒ЁЯЗж','ЁЯЗ▒ЁЯЗ╗','ЁЯЗ▒ЁЯЗз','ЁЯЗ▒ЁЯЗ╕','ЁЯЗ▒ЁЯЗ╖','ЁЯЗ▒ЁЯЗ╛','ЁЯЗ▒ЁЯЗо','ЁЯЗ▒ЁЯЗ╣','ЁЯЗ▒ЁЯЗ║','ЁЯЗ▓ЁЯЗ┤','ЁЯЗ▓ЁЯЗм','ЁЯЗ▓ЁЯЗ╝','ЁЯЗ▓ЁЯЗ╛','ЁЯЗ▓ЁЯЗ╗','ЁЯЗ▓ЁЯЗ▒','ЁЯЗ▓ЁЯЗ╣','ЁЯЗ▓ЁЯЗн','ЁЯЗ▓ЁЯЗ╢','ЁЯЗ▓ЁЯЗ╖','ЁЯЗ▓ЁЯЗ║','ЁЯЗ╛ЁЯЗ╣','ЁЯЗ▓ЁЯЗ╜','ЁЯЗлЁЯЗ▓','ЁЯЗ▓ЁЯЗй','ЁЯЗ▓ЁЯЗи','ЁЯЗ▓ЁЯЗ│','ЁЯЗ▓ЁЯЗк','ЁЯЗ▓ЁЯЗ╕','ЁЯЗ▓ЁЯЗж','ЁЯЗ▓ЁЯЗ┐','ЁЯЗ▓ЁЯЗ▓','ЁЯЗ│ЁЯЗж','ЁЯЗ│ЁЯЗ╖','ЁЯЗ│ЁЯЗ╡','ЁЯЗ│ЁЯЗ▒','ЁЯЗ│ЁЯЗи','ЁЯЗ│ЁЯЗ┐','ЁЯЗ│ЁЯЗо','ЁЯЗ│ЁЯЗк','ЁЯЗ│ЁЯЗм','ЁЯЗ│ЁЯЗ║','ЁЯЗ│ЁЯЗл','ЁЯЗ░ЁЯЗ╡','ЁЯЗ▓ЁЯЗ░','ЁЯЗ▓ЁЯЗ╡','ЁЯЗ│ЁЯЗ┤','ЁЯЗ┤ЁЯЗ▓','ЁЯЗ╡ЁЯЗ░','ЁЯЗ╡ЁЯЗ╝','ЁЯЗ╡ЁЯЗ╕','ЁЯЗ╡ЁЯЗж','ЁЯЗ╡ЁЯЗм','ЁЯЗ╡ЁЯЗ╛','ЁЯЗ╡ЁЯЗк','ЁЯЗ╡ЁЯЗн','ЁЯЗ╡ЁЯЗ│','ЁЯЗ╡ЁЯЗ▒','ЁЯЗ╡ЁЯЗ╣','ЁЯЗ╡ЁЯЗ╖','ЁЯЗ╢ЁЯЗж','ЁЯЗ╖ЁЯЗк','ЁЯЗ╖ЁЯЗ┤','ЁЯЗ╖ЁЯЗ║','ЁЯЗ╖ЁЯЗ╝','ЁЯЗ╕ЁЯЗ╜','ЁЯЗ╝ЁЯЗ╕','ЁЯЗ╕ЁЯЗ▓','ЁЯЗ╕ЁЯЗ╣','ЁЯЗ╕ЁЯЗж','ЁЯЗ╕ЁЯЗ│','ЁЯЗ╖ЁЯЗ╕','ЁЯЗ╕ЁЯЗи','ЁЯЗ╕ЁЯЗ▒','ЁЯЗ╕ЁЯЗм','ЁЯЗ╕ЁЯЗ░','ЁЯЗ╕ЁЯЗо','ЁЯЗ╕ЁЯЗз','ЁЯЗ╕ЁЯЗ┤','ЁЯЗ┐ЁЯЗж','ЁЯЗмЁЯЗ╕','ЁЯЗ░ЁЯЗ╖','ЁЯЗ╕ЁЯЗ╕','ЁЯЗкЁЯЗ╕','ЁЯЗ▒ЁЯЗ░','ЁЯЗ╕ЁЯЗй','ЁЯЗ╕ЁЯЗ╖','ЁЯЗ╕ЁЯЗп','ЁЯЗ╕ЁЯЗк','ЁЯЗиЁЯЗн','ЁЯЗ╕ЁЯЗ╛','ЁЯЗ╣ЁЯЗ╝','ЁЯЗ╣ЁЯЗп','ЁЯЗ╣ЁЯЗ┐','ЁЯЗ╣ЁЯЗн','ЁЯЗ╣ЁЯЗ▒','ЁЯЗ╣ЁЯЗм','ЁЯЗ╣ЁЯЗ░','ЁЯЗ╣ЁЯЗ┤','ЁЯЗ╣ЁЯЗ╣','ЁЯЗ╣ЁЯЗ│','ЁЯЗ╣ЁЯЗ╖','ЁЯЗ╣ЁЯЗ▓','ЁЯЗ╣ЁЯЗи','ЁЯЗ╣ЁЯЗ╗','ЁЯЗ║ЁЯЗм','ЁЯЗ║ЁЯЗж','ЁЯЗжЁЯЗк','ЁЯЗмЁЯЗз','ЁЯЗ║ЁЯЗ╕','ЁЯЗ║ЁЯЗ╛','ЁЯЗ║ЁЯЗ┐','ЁЯЗ╗ЁЯЗ║','ЁЯЗ╗ЁЯЗж','ЁЯЗ╗ЁЯЗк','ЁЯЗ╗ЁЯЗ│','ЁЯЗ╝ЁЯЗл','ЁЯЗкЁЯЗн','ЁЯЗ╛ЁЯЗк','ЁЯЗ┐ЁЯЗ▓','ЁЯЗ┐ЁЯЗ╝'];
      default:
        return ['ЁЯЩВ','ЁЯШК','ЁЯШВ','ЁЯдг'];
    }
  }
}