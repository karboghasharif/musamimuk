import 'print_open_orders_controller.dart';

/// Start/stop the designer open-order dock after auth or mode changes.
void syncPrintOpenOrdersAfterAuth({bool forceStop = false}) {
  if (forceStop) {
    PrintOpenOrdersController.instance.stop();
    return;
  }
  PrintOpenOrdersController.instance.start();
}

void syncPrintOpenOrdersAfterWorkMode() {
  PrintOpenOrdersController.instance.onWorkModeChanged();
}
