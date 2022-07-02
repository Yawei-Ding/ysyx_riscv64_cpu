#include <common.h>

static Context* do_event(Event e, Context* c) {
  switch (e.event) {
    case EVENT_YIELD: printf("irq event yield.\n"); break;
    case EVENT_ERROR: printf("irq event error.\n"); break;
    default: panic("Unhandled event ID = %d", e.event); break;
  }

  return c;
}

void init_irq(void) {
  Log("Initializing interrupt/exception handler...");
  cte_init(do_event);
}
