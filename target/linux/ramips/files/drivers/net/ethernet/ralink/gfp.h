#ifndef __BACKPORT_LINUX_GFP_H
#define __BACKPORT_LINUX_GFP_H
#include_next <linux/gfp.h>

#ifndef ___GFP_KSWAPD_RECLAIM
#define ___GFP_KSWAPD_RECLAIM	0x0u
#endif

#ifndef __GFP_KSWAPD_RECLAIM
#define __GFP_KSWAPD_RECLAIM	((__force gfp_t)___GFP_KSWAPD_RECLAIM) /* kswapd can wake */
#endif

struct page_frag_cache;
extern void __page_frag_cache_drain(struct page *page, unsigned int count);
extern void *__alloc_page_frag(struct page_frag_cache *nc, unsigned int fragsz, gfp_t gfp_mask);
extern void *page_frag_alloc(struct page_frag_cache *nc, unsigned int fragsz, gfp_t gfp_mask);
extern void __free_page_frag(void *addr);
extern void page_frag_free(void *addr);

#endif /* __BACKPORT_LINUX_GFP_H */
