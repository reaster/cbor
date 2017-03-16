/*
 * Package : Cbor
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/12/2016
 * Copyright :  S.Hamblett
 */

part of cbor;

/// What we are waiting for next, if anything.
enum whatsNext {
  aPositiveBignum,
  aNegativeBignum,
  aMultipleB64Url,
  aMultipleB64,
  aMultipleB16,
  encodedCBOR,
  aUri,
  nothing
}

class ListenerStack extends Listener {
  ItemStack _stack = new ItemStack();

  /// Get the stack
  ItemStack get stack => _stack;

  /// Used to indicate what the
  /// next decoded item should be.
  whatsNext _next = whatsNext.nothing;

  void onInteger(int value) {
    // Do not add nulls
    if (value == null) return;
    final DartItem item = new DartItem();
    item.data = value;
    item.type = dartTypes.dtInt;
    _append(item);
  }

  void onBytes(typed.Uint8Buffer data, int size) {
    // Check if we are expecting something, ie whats next
    switch (_next) {
      case whatsNext.aPositiveBignum:
      // Convert to a positive integer and append
        final int value = bignumToInt(data, "+");
        onInteger(value);
        break;
      case whatsNext.aNegativeBignum:
        int value = bignumToInt(data, "-");
        value = -1 + value;
        onInteger(value.abs());
        break;
      case whatsNext.aMultipleB64Url:
        if (data == null) return;
        final DartItem item = new DartItem();
        item.data = data;
        item.type = dartTypes.dtBuffer;
        item.hint = dataHints.base64Url;
        _append(item);
        break;
      case whatsNext.aMultipleB64:
        if (data == null) return;
        final DartItem item = new DartItem();
        item.data = data;
        item.type = dartTypes.dtBuffer;
        item.hint = dataHints.base64;
        _append(item);
        break;
      case whatsNext.aMultipleB16:
        if (data == null) return;
        final DartItem item = new DartItem();
        item.data = data;
        item.type = dartTypes.dtBuffer;
        item.hint = dataHints.base16;
        _append(item);
        break;
      case whatsNext.encodedCBOR:
        if (data == null) return;
        final DartItem item = new DartItem();
        item.data = data;
        item.type = dartTypes.dtBuffer;
        item.hint = dataHints.encodedCBOR;
        _append(item);
        break;
      case whatsNext.aUri:
        break;
      case whatsNext.nothing:
        if (data == null) return;
        final DartItem item = new DartItem();
        item.data = data;
        item.type = dartTypes.dtBuffer;
        _append(item);
        break;
      default:
        if (data == null) return;
        final DartItem item = new DartItem();
        item.data = data;
        item.type = dartTypes.dtBuffer;
        _append(item);
    }
    _next = whatsNext.nothing;
  }

  void onString(String str) {
    if (str == null) return;
    final DartItem item = new DartItem();
    item.data = str;
    item.type = dartTypes.dtString;
    switch (_next) {
      case whatsNext.aUri:
        item.hint = dataHints.uri;
        break;
      default:
        break;
    }
    _next = whatsNext.nothing;
    _append(item);
  }

  void onArray(int size) {}

  void onArrayElement(int value) {}

  void onMap(int size) {}

  void onTag(int tag) {
    // Switch on the tag type
    switch (tag) {
      case 0: // Date time string
      case 1: // Date/Time epoch
        break;
      case 2: // Positive bignum
        _next = whatsNext.aPositiveBignum;
        break;
      case 3: // Negative bignum
        _next = whatsNext.aNegativeBignum;
        break;
      case 21:
        _next = whatsNext.aMultipleB64Url;
        break;
      case 22:
        _next = whatsNext.aMultipleB64;
        break;
      case 23:
        _next = whatsNext.aMultipleB16;
        break;
      case 24:
        _next = whatsNext.encodedCBOR;
        break;
      case 32:
        _next = whatsNext.aUri;
        break;
      default:
        final String err = "Unimplemented tag type $tag";
        print(err);
        onError(err);
    }
  }

  void onSpecial(int code) {
    if (code == null) return;
    final DartItem item = new DartItem();
    item.data = code;
    item.type = dartTypes.dtInt;
    _append(item);
  }

  void onSpecialFloat(double value) {
    // Do not add nulls
    if (value == null) return;
    final DartItem item = new DartItem();
    item.data = value;
    item.type = dartTypes.dtDouble;
    _append(item);
  }

  void onBool(bool state) {
    // Do not add nulls
    if (state == null) return;
    final DartItem item = new DartItem();
    item.data = state;
    item.type = dartTypes.dtBool;
    _append(item);
  }

  void onNull() {
    final DartItem item = new DartItem();
    item.type = dartTypes.dtNull;
    _append(item);
  }

  void onUndefined() {
    final DartItem item = new DartItem();
    item.type = dartTypes.dtUndefined;
    _append(item);
  }

  void onError(String error) {
    if (error == null) return;
    final DartItem item = new DartItem();
    item.data = error;
    item.type = dartTypes.dtString;
    item.hint = dataHints.error;
    _append(item);
  }

  void onExtraInteger(int value, int sign) {
    onInteger(value);
  }

  void onExtraTag(int tag) {}

  void onExtraSpecial(int tag) {}

  void onIndefinate(String text) {}

  /// Main stack append method
  void _append(DartItem item) {
    _appendImpl(item);
  }

  /// Implementation
  void _appendImpl(DartItem item) {
    if (_stack.size() == 0) {
      // Empty stack, straight add
      item.complete = true;
      _stack.push(item);
    } else {
      final DartItem entry = _stack.peek();

      /// If its complete push
      /// our item. if not complete append and check
      /// for completeness.
      if (entry.complete) {
        item.complete = true;
        _stack.push(item);
      } else {
        // TODO
      }
    }
  }
}
