import { useRouter } from "next/router"
import { useEffect } from "react"
import Script from "next/script"

import { PostHogProvider } from "posthog-js/react"
import PlausibleProvider from "next-plausible"
import posthog from "posthog-js"

import analytics from "@/utils/analytics"

export default function AnalyticsWrapper({ children }) {
  const router = useRouter()

  useEffect(() => {
    analytics.handleRouteChange()

    router.events.on("routeChangeComplete", analytics.handleRouteChange)
    return () => {
      router.events.off("routeChangeComplete", analytics.handleRouteChange)
    }
  }, [])

  return (
    <>
      <PlausibleProvider
        domain="app.llmonitor.com,rollup.llmonitor.com"
        scriptProps={{
          src: "https://llmonitor.com/p/js/script.js",
          // @ts-ignore
          "data-api": "https://llmonitor.com/p/event",
        }}
        customDomain="llmonitor.com"
      >
        {process.env.NEXT_PUBLIC_CUSTOM_SCRIPT && (
          <Script
            id="custom-script"
            dangerouslySetInnerHTML={{
              __html: process.env.NEXT_PUBLIC_CUSTOM_SCRIPT,
            }}
            onLoad={() => console.log("Custom script loaded.")}
            onError={() => console.log("Custom script failed to load.")}
          />
        )}

        {process.env.NEXT_PUBLIC_LIVECHAT_SCRIPT && (
          <Script
            id="livechat-script"
            dangerouslySetInnerHTML={{
              __html: process.env.NEXT_PUBLIC_LIVECHAT_SCRIPT,
            }}
            onLoad={() => console.log("LiveChat script loaded.")}
            onError={() => console.log("LiveChat script failed to load.")}
          />
        )}

        {process.env.NEXT_PUBLIC_POSTHOG_KEY ? (
          <PostHogProvider client={posthog}>{children}</PostHogProvider>
        ) : (
          children
        )}
      </PlausibleProvider>
    </>
  )
}
