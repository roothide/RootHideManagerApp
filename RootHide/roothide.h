#if defined(ROOTHIDE_USE_STUB) && defined(THEOS_PACKAGE_SCHEME_ROOTHIDE)
#error "ROOTHIDE_USE_STUB defined, but THEOS_PACKAGE_SCHEME=roothide"
#elif defined(ROOTHIDE_USE_STUB) && !defined(THEOS_PACKAGE_SCHEME_ROOTHIDE)
#include "roothide/stub.h"
#else
#include "roothide/roothide.h"
#endif
