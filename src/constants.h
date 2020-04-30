#ifndef _WIN32
    #include <sys/mman.h>
    #define MEMMEM 1

    #if (__FreeBSD_version < 1200000)
        // libc's builtin is mostly slower than our local one
        #define MEMMEM 0
    #endif

#else
    #define MEMMEM 0
#endif




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


// FreeBSD

#ifdef MADV_NOSYNC
    #define NOSYNC 1
#else
    #define NOSYNC 0
    #define MADV_NOSYNC 0
#endif

#ifdef MADV_AUTOSYNC
    #define AUTOSYNC 1
#else
    #define AUTOSYNC 0
    #define MADV_AUTOSYNC 0
#endif

#ifdef MADV_CORE
    #define CORE 1
#else
    #define CORE 0
    #define MADV_CORE 0
    #define MADV_NOCORE 0
#endif

#ifdef MADV_PROTECT
    #define PROTECT 1
#else
    #define PROTECT 0
    #define MADV_PROTECT 0
#endif


// OpenBSD
#ifdef MADV_SPACEAVAIL
    #define SPACEAVAIL 1
#else
    #define SPACEAVAIL 0
    #define MADV_SPACEAVAIL 0
#endif
