#include <sys/mman.h>


// Linux:

#ifdef MADV_HWPOISON
    #define HWPOISON 1
#else
    #define HWPOISON 0
    #define MADV_HWPOISON 0
#endif

#ifdef MADV_MERGEABLE
    #define MERGEABLE 1
#else
    #define MERGEABLE 0
    #define MADV_MERGEABLE 0
#endif

#ifdef MADV_SOFT_OFFLINE
    #define SOFT_OFFLINE 1
#else
    #define SOFT_OFFLINE 0
    #define MADV_SOFT_OFFLINE 0
#endif

#ifdef MADV_HUGEPAGE
    #define HUGEPAGE 1
#else
    #define HUGEPAGE 0
    #define MADV_HUGEPAGE 0
#endif

#ifdef MADV_DODUMP
    #define DUMP 1
#else
    #define DUMP 0
    #define MADV_DODUMP 0
    #define MADV_DONTDUMP 0
#endif

#ifdef MADV_FREE
    #define FREE 1
#else
    #define FREE 0
    #define MADV_FREE 0
#endif

#ifdef MADV_WIPEONFORK
    #define ONFORK 1
#else
    #define ONFORK 0
    #define MADV_WIPEONFORK 0
    #define MADV_KEEPONFORK 0
#endif
