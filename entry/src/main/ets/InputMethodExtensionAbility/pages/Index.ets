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

// HELPER FUNCTIONS
function getLanguageName(code: LanguageCode): string {
  switch (code) {
    case 'ar': return 'Arabic';
    case 'en': return 'English';
    case 'it': return 'Italian';
    case 'pl': return 'Polish';
    case 'fa': return 'Persian';
    default: return 'English';
  }
}

function getVoiceDictationStatus(code: LanguageCode): string {
  switch (code) {
    case 'en': return 'Voice typing...';
    case 'pl': return 'Piszenie głosem...';
    case 'it': return 'Digitazione vocale...';
    case 'ar': return 'الكتابة الصوتية...';
    case 'fa': return 'تایپ صوتی...';
    default: return 'Voice typing...';
  }
}

// COMPONENTS
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
      // Shift key will use icon, so return empty string
      return '';
    }
    if (this.keyData.action === KeyAction.Enter) {
      // For search and send modes, show icon instead of text
      if (this.enterKeyLabel === 'Search' || this.enterKeyLabel === 'Send') {
        return '';
      }
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

        if (this.keyData.mainValue === 'icon' ||
          (this.keyData.action === KeyAction.Shift) ||
          (this.keyData.action === KeyAction.Enter && (this.enterKeyLabel === 'Search' || this.enterKeyLabel === 'Send'))) {

          // Show icons for special keys
          if (this.keyData.action === KeyAction.Shift) {
            Image($r('app.media.shift_icon'))
              .width(20)
              .height(20)
              .fillColor(this.shiftState !== ShiftState.Off ? OpenBoardTheme.accent : OpenBoardTheme.primaryText)
          } else if (this.keyData.action === KeyAction.Enter && this.enterKeyLabel === 'Search') {
            Image($r('app.media.search_icon'))
              .width(20)
              .height(20)
          } else if (this.keyData.action === KeyAction.Enter && this.enterKeyLabel === 'Send') {
            Image($r('app.media.send_icon'))
              .width(20)
              .height(20)
          } else if (this.keyData.mainValue === 'icon') {
            Image($r('app.media.emoji_icon'))
              .width(20)
              .height(20)
          }
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
  @State enterKeyLabel: string = 'Enter';
  @State availableLanguages: LanguageCode[] = ['en'];

  @State showEmojiPanel: boolean = false;
  @State emojiCategory: string = 'Smileys & Emotion';
  private emojiScroller: Scroller = new Scroller();

  @State private previousWord: string = '';
  @State private currentWord: string = '';
  @State private suggestions: string[] = ['', '', ''];

  @State private clipboardHistory: string[] = ['wklej', 'kod', 'przykładowy', 'do', 'projektu', 'OpenBoard'];

  @State private isRecording: boolean = false;
  @State private languageIndicatorOpacity: number = 0;

  // Timer for inactivity detection
  @State private inactivityTimer: number = -1;
  @State private showPreTypingToolbar: boolean = true;
  @State private lastTypingActivity: number = Date.now();

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
      const timeSinceLastActivity = Date.now() - this.lastTypingActivity;
      if (!this.isRecording && !this.showEmojiPanel && timeSinceLastActivity >= 8000) {
        this.showPreTypingToolbar = true;
      }
      this.startInactivityTimer(); // Continue checking
    }, 1000); // Check every second
  }

  private resetInactivityTimer(): void {
    this.lastTypingActivity = Date.now();
    this.showPreTypingToolbar = false;
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
        this.enterKeyLabel = 'Enter';
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
    // Don't reset timer for emoji panel toggle
    if (key.action !== KeyAction.EMOJI_PANEL) {
      this.resetInactivityTimer();
    }

    if (this.isRecording) {
      this.isRecording = false;
      console.info('Pisanie głosem przerwane przez ręczny wpis.');
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
      console.info('Pisanie głosem przerwane przez otwarcie schowka.');
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
    const boundaries = [' ', '\n', ',', '.', '!', '?', ';', ':', '/', '\\', '-', '_', '"', "'", '(', ')', '[', ']', '<', '>'];
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
      // CLOSE ICON
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

      // SUGGESTIONS
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

      // MICROPHONE
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
      // CLOSE ICON
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

      // CLIPBOARD ICON
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

      // EMPTY SPACE
      Flex().layoutWeight(1)

      // MICROPHONE
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
      // RETURN TO KEYBOARD BUTTON - using return icon
      Column() {
        Image($r('app.media.return_icon'))
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
      .onClick(() => {
        this.showEmojiPanel = false;
        // Don't reset timer when returning from emoji panel
      })

      // EMPTY SPACE
      Flex().layoutWeight(1)

      // EMPTY SPACE
      Flex().layoutWeight(1)
    }
  }

  @Builder
  buildVoiceToolbar() {
    Row({ space: 3 }) {
      // CLOSE ICON
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

      // VOICE RECORDING STATUS
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
        // MAIN TOOLBAR - CONDITIONAL RENDERING
        Row({ space: 3 }) {
          if (this.isRecording) {
            // Toolbar when typing with voice
            this.buildVoiceToolbar()
          } else if (this.showEmojiPanel) {
            // Toolbar when in emoji tab
            this.buildEmojiToolbar()
          } else if (this.showPreTypingToolbar) {
            // Toolbar before starting to type and after 8 sec of not typing
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

        // MAIN CONTENT
        if (!this.showEmojiPanel) {
          // Main keyboard
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
          // Emoji Panel
          Column({ space: 10 }) {
            // Emoji Categories
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
                    .onClick(() => { this.emojiCategory = cat; })
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
                      // Don't reset timer for emoji usage
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

      // Popups
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
        // Emocje, gesty, buźki, serduszka
        return ['😀','😁','😂','🤣','😃','😄','😅','😆','😉','😊','😋','😎','🥰','😍','😘','😗','😙','😚','🥲','🥳','🤩','🤗','🤔','🤨','😐','😶','😏','😒','🙄','😬','🤥','😟','😔','😥','🤤','😫','😩','🥺','😭','😤','😮','😱','😳','🤯','🥵','🥶','😴','😵','😷','🤕','🤢','🤮','🤧','😇','😈','👿','👹','👺','💀','👻','👽','🤖','💩','😺','😸','😹','😻','😼','😽','😾','😿','🙀','🫶','👍','👎','✊','👊','🤝','🤞','✌️','🫰','🤟','🤘','👌','🤌','🤏','👈','👉','👆','👇','☝️','✋','🤚','🖐️','SS','💪','🙏','✍️','💅','👂','👃','👁️','🧠','🦷','🦴','🗣️','👤','👥','🫂'];
      case 'People':
        // Ludzie, części ciała, zawody, rodziny
        return ['👶','👧','🧒','👦','👩','🧑','👨','👵','🧓','👴','👱‍♀️','👱','👱‍♂️','👮‍♀️','👮','👮‍♂️','🧑‍⚕️','👨‍⚕️','👩‍⚕️','🧑‍🎓','👨‍🎓','👩‍🎓','🧑‍🏫','👨‍🏫','👩‍🏫','🧑‍⚖️','👨‍⚖️','👩‍⚖️','🧑‍🌾','👨‍🌾','👩‍🌾','🧑‍🍳','👨‍🍳','👩‍🍳','🧑‍🔧','👨‍🔧','👩‍🔧','🧑‍🏭','👨‍🏭','👩‍🏭','🧑‍💼','👨‍💼','👩‍💼','🧑‍🔬','👨‍🔬','👩‍🔬','🧑‍💻','👨‍💻','👩‍💻','🧑‍🎤','👨‍🎤','👩‍🎤','🧑‍🎨','👨‍🎨','👩‍🎨','🧑‍✈️','👨‍✈️','👩‍✈️','🧑‍🚀','👨‍🚀','👩‍🚀','🧑‍🚒','👨‍🚒','👩‍🚒','💂‍♀️','💂','💂‍♂️','🕵️‍♀️','🕵️','🕵️‍♂️','🥷','🤵‍♀️','🤵','🤵‍♂️','👰‍♀️','👰','👰‍♂️','🤰','🤱','🧑‍🍼','👨‍🍼','👩‍🍼','👼','🎅','🤶','🧑‍🎄','🦸‍♀️','🦸','🦸‍♂️','🦹‍♀️','🦹','🦹‍♂️','🧙‍♀️','🧙','🧙‍♂️','🧚‍♀️','🧚','🧚‍♂️','🧛‍♀️','🧛','🧛‍♂️','🧜‍♀️','🧜','🧜‍♂️','🧝‍♀️','🧝','🧝‍♂️','🧞‍♀️','🧞','🧞‍♂️','🧟‍♀️','🧟','🧟‍♂️','🚶‍♀️','🚶','🚶‍♂️','🏃‍♀️','🏃','🏃‍♂️','🕺','💃','🧑‍🦽','👨‍🦽','👩‍🦽','🧑‍🦼','👨‍🦼','👩‍🦼','🧍‍♀️','🧍','🧍‍♂️',' sitting person','🧎‍♀️','🧎','🧎‍♂️',' kneeling person','🧑‍🦯','👨‍🦯','👩‍🦯','🧑‍ standing','👨‍ standing','👩‍ standing','👩‍❤️‍👨','👨‍❤️‍👨','👩‍❤️‍👩','👪','💋','💘','💝','💖','💗','💓','💞','💕','🧡','💛','💚','💙','💜','🤎','🖤','🤍','💯','💢','💥','💫','💦','💨','💬','👁️‍🗨️','💭','💡','🔥'];
      case 'Animals & Nature':
        // Zwierzęta, rośliny, pogoda, krajobrazy
        // Zastąpiono tekstowe nazwy emoji ich wizualnymi odpowiednikami
        return ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐽','🐸','🐵','🐒','🦍','🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦢','🦅','🦉','🦩','🦚','🦜','🕊️','🐺','🐗','🐴','🦓','🦌','🦏','🦛','🦒','🐪','🐫','🐘','🦥','🦦','🦨','🦔','🐿️','🐁','🐀','🐇','🐈','🐉','🐲','🐊','🐢','🐍','🦎','🦖','🦕','🐋','🐳','🐬','🐠','🐡','🦈','🐙','🦑','🦐','🦀','🦞','🐌','🦋','🐛','🐜','🐝','🐞','🦗','🕷️','🦂','🦠','💐','🌸','🌼','🌻','🌷','🌹','🥀','🌺','🪴','🌲','🌳','🌴','🌵','🌾','🌿','☘️','🍀','🍁','🍂','🍃','🍄','🌰','🌎','🌍','🌏','🌑','🌕','🌓','🌔','🌖','🌗','🌘','🌙','⭐','🌟','✨','⚡','🔥','☀️','🌤️','⛅','🌥️','🌦️','☁️','🌨️','🌧️','⛈️','🌩️','❄️','⛄','🌬️','💨','🌪️','🌀','🌈','🌊','💧','☔','☂️','💦'];
      case 'Food & Drink':
        // Owoce, warzywa, dania, słodycze, napoje
        return ['🍎','🍏','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🍆','🥕','🌽','🌶️','🥒','🥦','🫑','🧅','🧄','🥔','🍠','🥐','🍞','🥖','🥨','🥯','🥞','🧇','🧀','🥩','🍗','🍖','🥓','🍔','🍟','🍕','🌭','🥪','🌮','🌯','🥙','🥚','🍳','🥘','🍲','🥣','🥗','🍿','🧈','🧂','🥫','🍱','🍙','🍚','🍘','🍥','🍣','🍤','🍜','🍝','🍛','🍠','🍢','🍡','🥟','🥠','🥡','🍦','🍧','🍨','🍩','🍪','🎂','🍰','🧁','🥧','🍫','🍬','🍭','🍮','🍯','🍼','🥛','☕','🍵','🥤','🧋','🫗','🍺','🍻','🍷','🥂','🍾','🥃','🍸','🍹','🍶','🧊','🥣','🍴','🥄','🥢','🥡','🧧'];
      case 'Activity & Event':
        // Sport, hobby, muzyka, święta, wydarzenia
        return ['⚽','🏀','🏈','⚾','🥎','🎾','🏐','🏉','🎱','🏓','🏸','🥊','🥋','⛸️','🎿','🏂','⛷️','🏹','🎯','🎳','⛳','🎣','🏊‍♂️','🚴‍♂️','🏃‍♂️','🚶‍♂️','🩰','🎤','🎧','🎼','🎹','🥁','🎸','🎺','🎻','🎬','🎭','🖼️','🎨','🧵','🧶','🎲','♟️','🧩','🧸','🎮','🕹️','🎰','🎡','🎢','🎠','🎊','🎉','🎁','🎈','🎀','🎗️','🎟️','🎫','🎖️','🏆','🏅','🥇','🥈','🥉','🔔','🎄','🎅','🎃','👻','🎂','💍','💎','💰','💲','💸','💵','💶','💷','💴','💳','🧾','🔗','🔒','🔓','🔑'];
      case 'Travel & Places':
        // Pojazdy, miejsca, budynki
        // Zastąpiono tekstowe nazwy emoji ich wizualnymi odpowiednikami
        return ['🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐','🚚','🚛','🚜','🏍️','🛵','🚲','🛴','🚨','⛽','🛣️','🛤️','🚏','🚦','🚥','🚧','⚓','🚢','⛴️','🚤','🛥️','🛳️','🚀','🛸','🚁','🚂','🚃','🚋','🚌','🚆','🚇','🚊','🚉','✈️','🛫','🛬','💺','🏨','🏩','house emoji','🏠','🏡','🏘️','🏚️','🏗️','🏢','🏭','🏬','🏣','🏤','🏦','🏥','🏫','🏤','⛪','🕌','🕍','🕋','⛲','🗼','🗽','🗾','🌋','🏞️','🗻','🏖️','🏜️','🏝️','⛺','🌃','🏙️','🌄','🌅','🌇','🌆','🌉','🌌','🌠','🎇','🎆'];
      case 'Objects':
        // Przedmioty, narzędzia, ubrania, elektronika
        return ['⌚','📱','💻','⌨️','🖨️','🖱️','📷','📸','📹','📼','💿','📀','📻','📺','📞','📠','🔋','🔌','💡','🔦','🕯️','🗑️','🛒','✉️','📧','📩','📨','📤','📥','📦','📫','📪','📬','📭','📮','📜','📃','📄','📑','📅','🗓️','📇','📈','📉','📊','📋','📌','📍','📎','🖇️','📏','📐','✂️','🪚','🔨','⛏️','🪓','🔪','🔫','🩺','🧪','🌡️','💉','💊','🩹','🚪','🪑','🛋️','🛏️','🛀','🧼','🧽','🧺','🚽','🚿','🛁','🪠','🧴','👚','👕','👖','👔','👗','👙','👘','🥻','🩱','🩲','🩳','🧥','🥼','🧣','🧤','🧢','👒','🎓','👑','💍','💎','💄','💅','🪮','🪒','🪥','🪣','🪤','🪟','🪜','🪞','🪚','🪛','🛠️','⚙️','🧱','⛓️','🔗','📏','🧮'];
      case 'Symbols':
        // Znaki, strzałki, cyfry, emotikony tekstowe
        return ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❗️','❓','‼️','⁉️','✅','❌','✔️','✖️','➕','➖','➗','♾️','©️','®️','™️','℠','®️','™️','©️','®️','™️','℠','#️⃣','*️⃣','0️⃣','1️⃣','2️⃣','3️⃣','4️⃣','5️⃣','6️⃣','7️⃣','8️⃣','9️⃣','🔟','⬆️','⬇️','⬅️','➡️','↖️','↗️','↘️','↙️','↕️','↔️','↩️','↪️','⤴️','⤵️','🔄','◀️','▶️','🔼','🔽','⏏️','➿','♻️','⚜️','🔱','⚠️','⛔','🚫','🚭','🚳','🚱','🚷','📵','🔞',' P','🅿️','🚸','🈯','🈚','🈶','🈲','🈹','🈺','🈷️','🈂️','🉑','🈴','🈳','㊗️','㊙️','❌','⭕','🛑','⛑️','👑','🔑','🔔','🔕','🎶','🎵','➕','➖','➗','✖️','➿','✔️','☑️','✅','⭕','❌','🛑','⚠️','❗','❓'];
      case 'Flags':
        // Wybrane flagi
        return ['🏳️','🏴','🏁','🚩','🇦🇫','🇦🇽','🇦🇱','🇩🇿','🇦🇸','🇦🇩','🇦🇴','🇦🇮','🇦🇶','🇦🇬','🇦🇷','🇦🇲','🇦🇼','🇦🇺','🇦🇹','🇦🇿','🇧🇸','🇧🇭','🇧🇩','🇧🇧','🇧🇾','🇧🇪','🇧🇿','🇧🇯','🇧🇲','🇧🇹','🇧🇴','🇧🇦','🇧🇼','🇧🇷','🇮🇴','🇻🇬','🇧🇳','🇧🇬','🇧🇫','🇧🇮','🇰🇭','🇨🇲','🇨🇦','🇮🇨','🇨🇻','🇧🇶','🇰🇾','🇨🇫','🇹🇩','🇨🇱','🇨🇳','🇨🇽','🇨🇨','🇨🇴','🇰🇲','🇨🇬','🇨🇩','🇨🇰','🇨🇷','🇭🇷','🇨🇺','🇨🇼','🇨🇾','🇨🇿','🇩🇰','🇩🇯','🇩🇲','🇩🇴','🇪🇨','🇪🇬','🇸🇻','🇬🇶','🇪🇷','🇪🇪','🇸🇿','🇪🇹','🇪🇺','🇫🇰','🇫🇴','🇫🇯','🇫🇮','🇫🇷','🇬🇫','🇵🇫','🇹🇫','🇬🇦','🇬🇲','🇬🇪','🇩🇪','🇬🇭','🇬🇮','🇬🇷','🇬🇱','🇬🇩','🇬🇵','🇬🇺','🇬🇹','🇬🇬','🇬🇳','🇬🇼','🇬🇾','🇭🇹','🇭🇳','🇭🇰','🇭🇺','🇮🇸','🇮🇳','🇮🇩','🇮🇷','🇮🇶','🇮🇪','🇮🇲','🇮🇱','🇮🇹','🇯🇲','🇯🇵','🇯🇪','🇯🇴','🇰🇿','🇰🇪','🇰🇮','🇽🇰','🇰🇼','🇰🇬','🇱🇦','🇱🇻','🇱🇧','🇱🇸','🇱🇷','🇱🇾','🇱🇮','🇱🇹','🇱🇺','🇲🇴','🇲🇬','🇲🇼','🇲🇾','🇲🇻','🇲🇱','🇲🇹','🇲🇭','🇲🇶','🇲🇷','🇲🇺','🇾🇹','🇲🇽','🇫🇲','🇲🇩','🇲🇨','🇲🇳','🇲🇪','🇲🇸','🇲🇦','🇲🇿','🇲🇲','🇳🇦','🇳🇷','🇳🇵','🇳🇱','🇳🇨','🇳🇿','🇳🇮','🇳🇪','🇳🇬','🇳🇺','🇳🇫','🇰🇵','🇲🇰','🇲🇵','🇳🇴','🇴🇲','🇵🇰','🇵🇼','🇵🇸','🇵🇦','🇵🇬','🇵🇾','🇵🇪','🇵🇭','🇵🇳','🇵🇱','🇵🇹','🇵🇷','🇶🇦','🇷🇪','🇷🇴','🇷🇺','🇷🇼','🇸🇽','🇼🇸','🇸🇲','🇸🇹','🇸🇦','🇸🇳','🇷🇸','🇸🇨','🇸🇱','🇸🇬','🇸🇰','🇸🇮','🇸🇧','🇸🇴','🇿🇦','🇬🇸','🇰🇷','🇸🇸','🇪🇸','🇱🇰','🇸🇩','🇸🇷','🇸🇯','🇸🇪','🇨🇭','🇸🇾','🇹🇼','🇹🇯','🇹🇿','🇹🇭','🇹🇱','🇹🇬','🇹🇰','🇹🇴','🇹🇹','🇹🇳','🇹🇷','🇹🇲','🇹🇨','🇹🇻','🇺🇬','🇺🇦','🇦🇪','🇬🇧','🇺🇸','🇺🇾','🇺🇿','🇻🇺','🇻🇦','🇻🇪','🇻🇳','🇼🇫','🇪🇭','🇾🇪','🇿🇲','🇿🇼'];
      default:
        return ['🙂','😊','😂','🤣'];
    }
  }
}