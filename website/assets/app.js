(function () {
  "use strict";

  /* ------------------------------------------------------------------ */
  /* Translations                                                       */
  /* ------------------------------------------------------------------ */

  const translations = {
    en: {
      "meta.title": "LocalInk — Screen annotation for macOS",
      "meta.description":
        "LocalInk is a free, open-source macOS menu-bar app for drawing, highlighting, and spotlighting your screen over any app. Offline, lightweight, and private.",
      "meta.ogTitle": "LocalInk — Make your point. Keep your flow.",
      "meta.ogDescription":
        "A native, offline macOS screen-annotation app for presentations, lessons, and recordings.",

      "nav.skip": "Skip to content",
      "nav.home": "LocalInk home",
      "nav.product": "Product",
      "nav.demo": "Demo",
      "nav.how": "How it works",
      "nav.faq": "FAQ",
      "nav.github": "GitHub",
      "nav.language": "Language",
      "nav.download": "Download",
      "nav.menu": "Open menu",
      "nav.close": "Close menu",

      "hero.eyebrow": "Native macOS · Free & open source",
      "hero.title": 'Make your point.<br /><span class="accent">Keep your flow.</span>',
      "hero.lede":
        "LocalInk is a lightweight screen-annotation layer for macOS. Draw, highlight, and spotlight anything on your desktop — over any app, without interrupting what is underneath.",
      "hero.primary": "Download for Mac",
      "hero.secondary": "See it in action",
      "hero.meta": "macOS 13 or later · Universal · Under 1 MB · No account, no telemetry",
      "hero.badge": "Live on macOS",
      "hero.imageAlt":
        "LocalInk annotating a presentation with a circle, arrow, cursor halo, and spotlight",
      "hero.caption": "One toolbar. Every app. Nothing to switch between.",

      "trust.label": "Works over the apps you already use",

      "overview.eyebrow": "The product",
      "overview.title": "One quiet layer over your entire desktop.",
      "overview.sub":
        "LocalInk adds a native drawing surface above macOS, then gets out of the way. No window juggling, no screenshots, no context switch.",
      "overview.card1.title": "Annotate",
      "overview.card1.body":
        "Pen, arrow, shapes, text, redaction, and a sequential counter for step-by-step explanations.",
      "overview.card2.title": "Direct attention",
      "overview.card2.body":
        "A cursor halo, click ripples, and a spotlight that dims everything except the detail you mean.",
      "overview.card3.title": "Stay in flow",
      "overview.card3.body":
        "Every click, drag, and scroll reaches the app underneath. Cursor effects stay click-through.",

      "features.eyebrow": "Capabilities",
      "features.title": "Everything you need for a clear explanation.",
      "features.sub":
        "A focused toolset built around live presentations, teaching, and screen recordings.",

      "feature1.tag": "Annotate",
      "feature1.title": "Draw over anything",
      "feature1.body":
        "Use pens, highlighters, text, arrows, and shapes to emphasize a point in real time — over slides, code, PDFs, videos, or a live demo.",
      "feature1.b1": "Pen, arrow, line, rectangle, ellipse, highlighter, and text",
      "feature1.b2": "Solid redaction and a sequential counter",
      "feature1.b3": "Shift-constrained shapes and 45° arrow snapping",
      "feature1.link": "Download for Mac →",
      "feature1.imageAlt": "Annotated slide with an arrow and a circle",

      "feature2.tag": "Direct attention",
      "feature2.title": "Keep every eye on the pointer",
      "feature2.body":
        "A polished ring follows your cursor so viewers never lose their place. Spotlight the detail that matters while the app underneath stays fully interactive.",
      "feature2.b1": "Custom halo color, size, and opacity",
      "feature2.b2": "Spotlight with an adjustable aperture",
      "feature2.b3": "Click ripples, magnifier, and full-screen zoom",
      "feature2.link": "Download for Mac →",
      "feature2.imageAlt": "Spotlight dimming the screen except around the cursor",

      "feature3.tag": "Capture & share",
      "feature3.title": "A clean canvas, ready to share",
      "feature3.body":
        "Switch to a whiteboard for a clutter-free explanation, then export exactly what you see as a PNG or SVG — without LocalInk's controls in the frame.",
      "feature3.b1": "Whiteboard with a separate canvas",
      "feature3.b2": "PNG export and clipboard copy",
      "feature3.b3": "Vector SVG export for documentation",
      "feature3.link": "Download for Mac →",
      "feature3.imageAlt": "Whiteboard with marker drawings",

      "stats.eyebrow": "Small by design",
      "stats.title": "Native, fast, and quiet.",
      "stats.sub":
        "No web runtime. No background services. Nothing to configure before you present.",
      "stats.1": "Download size",
      "stats.2": "Network requests",
      "stats.3": "Apple Silicon & Intel",
      "stats.4": "macOS version",

      "demo.eyebrow": "Try it",
      "demo.title": "The toolbar, right in your browser.",
      "demo.sub":
        "Draw on the slide below. The real app works this way over every window on your Mac.",
      "demo.toolbar": "Demo tools",
      "demo.pen": "Pen",
      "demo.arrow": "Arrow",
      "demo.rect": "Rectangle",
      "demo.ellipse": "Ellipse",
      "demo.highlighter": "Highlighter",
      "demo.undo": "Undo",
      "demo.clear": "Clear",
      "demo.width": "Width",
      "demo.canvas": "Interactive drawing demo",
      "demo.kicker": "PRODUCT DEMO",
      "demo.slideTitle": "Make the point.<br />Keep the flow.",
      "demo.slideBody":
        "Draw anywhere on this slide. The controls above mirror LocalInk's floating toolbar.",
      "demo.drawHere": "Draw here",

      "color.red": "Red",
      "color.orange": "Orange",
      "color.yellow": "Yellow",
      "color.green": "Green",
      "color.blue": "Blue",
      "color.purple": "Purple",
      "color.white": "White",
      "color.black": "Black",

      "how.eyebrow": "How it works",
      "how.title": "Three steps. No context switch.",
      "how.step1.title": "Open and start",
      "how.step1.body":
        "Launch LocalInk and click Start Drawing, or press ⌃⌥D from anywhere.",
      "how.step2.title": "Draw and direct",
      "how.step2.body":
        "Annotate any app. Turn on the halo or spotlight to point without hiding the interface.",
      "how.step3.title": "Return to work",
      "how.step3.body":
        "Turn drawing off. Every click, drag, and scroll belongs to your app again.",

      "privacy.eyebrow": "Private by default",
      "privacy.title": "Your screen never leaves your Mac.",
      "privacy.body":
        "LocalInk is built for sensitive work. It runs fully offline with no account and no analytics. Drawing, halo, and spotlight never need screen-recording permission; only optional zoom and export do.",
      "privacy.c1": "No sign-up, subscription, or telemetry",
      "privacy.c2": "No network code at runtime",
      "privacy.c3": "Images are saved only where you choose",
      "privacy.c4": "Open source under the MIT license",
      "privacy.cloud": "Cloud whiteboards",
      "privacy.r1": "Works offline",
      "privacy.r2": "Account required",
      "privacy.r3": "Annotate over any app",
      "privacy.r4": "Download size",
      "privacy.r5": "Screen pixels uploaded",
      "privacy.yes": "Yes",
      "privacy.no": "No",
      "privacy.never": "Never",
      "privacy.rarely": "Rarely",
      "privacy.usually": "Usually",
      "privacy.often": "Often",
      "privacy.browser": "In a browser tab",
      "privacy.big": "100 MB+",

      "usecases.eyebrow": "Who it's for",
      "usecases.title": "Built for people who explain things.",
      "usecases.1.title": "Educators",
      "usecases.1.body":
        "Mark up slides and code while teaching, then hand control back without switching apps.",
      "usecases.2.title": "Presenters",
      "usecases.2.body":
        "Point out a control in a live demo and keep the audience on the exact step you mean.",
      "usecases.3.title": "Designers",
      "usecases.3.body":
        "Circle a detail in a review and annotate directly on the interface you are discussing.",
      "usecases.4.title": "Support",
      "usecases.4.body":
        "Walk someone through on-screen steps with clear marks and a visible cursor.",
      "usecases.5.title": "Creators",
      "usecases.5.body":
        "Record annotated tutorials with a clean, native overlay that stays out of the capture.",
      "usecases.6.title": "Developers",
      "usecases.6.body":
        "Explain a code path in a shared editor, spotlight a log line, and zoom into a small detail.",

      "download.eyebrow": "Download",
      "download.title": "Ready when you are.",
      "download.sub": "Free forever. No account. No strings.",
      "download.zip": "Download LocalInk.zip",
      "download.dmg": "Download .dmg",
      "download.meta": "Version 1.0.2 · Universal · macOS 13 or later · ~0.6 MB",
      "download.installTitle": "Install",
      "download.install1": "Download and unzip LocalInk.zip.",
      "download.install2": "Drag LocalInk.app into Applications.",
      "download.install3": "Open it and click Start Drawing.",
      "download.firstTitle": "First launch",
      "download.firstBody":
        "LocalInk is not notarized with a paid Apple account. If macOS blocks the first launch, use System Settings → Privacy & Security → Open Anyway, or right-click the app and choose Open. You only do this once.",
      "download.specific": "Prefer a specific version?",
      "download.allReleases": "See all releases on GitHub",

      "faq.eyebrow": "FAQ",
      "faq.title": "Good to know.",
      "faq.q1": "Is LocalInk really free?",
      "faq.a1":
        "Yes. It is free and open source under the MIT license. There is no paid tier, account, or trial.",
      "faq.q2": "Does it collect any data?",
      "faq.a2":
        "No. There is no telemetry, no analytics, and no network access in the app. Your screen content never leaves your Mac.",
      "faq.q3": "Does it need Screen Recording permission?",
      "faq.a3":
        "Only the optional magnifier, full-screen zoom, and image export need it. Drawing, halo, and spotlight work without any capture permission.",
      "faq.q4": "Why does macOS warn me the first time?",
      "faq.a4":
        "The app is not notarized with a paid Apple Developer account. Use System Settings → Privacy & Security → Open Anyway once, or right-click the app and choose Open.",
      "faq.q5": "Which Macs are supported?",
      "faq.a5":
        "macOS 13 or later, on both Apple Silicon and Intel Macs. The download is a universal build.",
      "faq.q6": "Can I use it while sharing my screen?",
      "faq.a6":
        "Yes. Sharing your entire display generally captures overlays correctly. Sharing a single window may not include the overlay, so verify the behavior in your meeting or recording app.",

      "footer.tagline":
        "A native macOS screen-annotation layer for presentations, lessons, and recordings.",
      "footer.product": "Product",
      "footer.resources": "Resources",
      "footer.project": "Project",
      "footer.releases": "Releases",
      "footer.license": "MIT License",
      "footer.issues": "Issues",
      "footer.changelog": "Changelog",
      "footer.top": "Back to top",
      "footer.made": "Made by Anh Nguyen (Jerry)",
      "footer.copy": "© 2026 LocalInk. Built with AppKit. No cookies, no tracking."
    },

    vi: {
      "meta.title": "LocalInk — Chú thích màn hình cho macOS",
      "meta.description":
        "LocalInk là ứng dụng miễn phí, mã nguồn mở trên thanh menu macOS để vẽ, tô sáng và làm nổi bật màn hình trên mọi ứng dụng. Hoạt động ngoại tuyến, nhẹ và riêng tư.",
      "meta.ogTitle": "LocalInk — Nói đúng ý. Giữ nhịp làm việc.",
      "meta.ogDescription":
        "Ứng dụng chú thích màn hình native, ngoại tuyến cho macOS, dành cho thuyết trình, giảng dạy và ghi màn hình.",

      "nav.skip": "Chuyển đến nội dung",
      "nav.home": "Trang chủ LocalInk",
      "nav.product": "Sản phẩm",
      "nav.demo": "Dùng thử",
      "nav.how": "Cách hoạt động",
      "nav.faq": "Hỏi đáp",
      "nav.github": "GitHub",
      "nav.language": "Ngôn ngữ",
      "nav.download": "Tải xuống",
      "nav.menu": "Mở menu",
      "nav.close": "Đóng menu",

      "hero.eyebrow": "macOS native · Miễn phí & mã nguồn mở",
      "hero.title": 'Nói đúng ý.<br /><span class="accent">Giữ nhịp làm việc.</span>',
      "hero.lede":
        "LocalInk là lớp chú thích màn hình nhẹ cho macOS. Vẽ, tô sáng và làm nổi bật bất cứ thứ gì trên desktop — ngay trên mọi ứng dụng, mà không làm gián đoạn công việc bên dưới.",
      "hero.primary": "Tải cho Mac",
      "hero.secondary": "Xem demo",
      "hero.meta": "macOS 13 trở lên · Universal · Dưới 1 MB · Không tài khoản, không telemetry",
      "hero.badge": "Đang chạy trên macOS",
      "hero.imageAlt":
        "LocalInk chú thích một bài thuyết trình bằng vòng tròn, mũi tên, vòng sáng quanh con trỏ và spotlight",
      "hero.caption": "Một thanh công cụ. Mọi ứng dụng. Không cần chuyển đổi.",

      "trust.label": "Hoạt động trên những ứng dụng bạn đã dùng",

      "overview.eyebrow": "Sản phẩm",
      "overview.title": "Một lớp mỏng, yên tĩnh phủ lên toàn bộ desktop.",
      "overview.sub":
        "LocalInk thêm một bề mặt vẽ native phía trên macOS, rồi lập tức nhường chỗ. Không chuyển cửa sổ, không chụp màn hình, không ngắt mạch.",
      "overview.card1.title": "Chú thích",
      "overview.card1.body":
        "Bút, mũi tên, hình khối, văn bản, che thông tin và bộ đếm tuần tự cho từng bước giải thích.",
      "overview.card2.title": "Điều hướng sự chú ý",
      "overview.card2.body":
        "Vòng sáng quanh con trỏ, gợn sóng khi bấm và spotlight làm tối mọi thứ trừ chi tiết bạn muốn nhấn mạnh.",
      "overview.card3.title": "Không ngắt mạch",
      "overview.card3.body":
        "Mọi cú bấm, kéo và cuộn vẫn đến ứng dụng bên dưới. Hiệu ứng con trỏ luôn xuyên qua.",

      "features.eyebrow": "Khả năng",
      "features.title": "Mọi thứ bạn cần cho một lời giải thích rõ ràng.",
      "features.sub":
        "Bộ công cụ gọn gàng, thiết kế cho thuyết trình trực tiếp, giảng dạy và ghi màn hình.",

      "feature1.tag": "Chú thích",
      "feature1.title": "Vẽ lên mọi thứ",
      "feature1.body":
        "Dùng bút, bút dạ quang, văn bản, mũi tên và hình khối để nhấn mạnh ý tưởng ngay lập tức — trên slide, code, PDF, video hoặc một buổi demo trực tiếp.",
      "feature1.b1": "Bút, mũi tên, đường thẳng, chữ nhật, ellipse, bút dạ quang và văn bản",
      "feature1.b2": "Che thông tin dạng khối và bộ đếm tuần tự",
      "feature1.b3": "Hình khối ràng buộc bằng Shift và mũi tên bám 45°",
      "feature1.link": "Tải cho Mac →",
      "feature1.imageAlt": "Slide được chú thích với một mũi tên và một vòng tròn",

      "feature2.tag": "Điều hướng sự chú ý",
      "feature2.title": "Giữ mọi ánh nhìn vào con trỏ",
      "feature2.body":
        "Vòng sáng tinh tế theo con trỏ để người xem không bị lạc. Làm nổi bật chi tiết quan trọng trong khi ứng dụng bên dưới vẫn tương tác bình thường.",
      "feature2.b1": "Tùy chỉnh màu, kích thước và độ mờ của vòng sáng",
      "feature2.b2": "Spotlight với khẩu độ điều chỉnh được",
      "feature2.b3": "Gợn sóng khi bấm, kính lúp và zoom toàn màn hình",
      "feature2.link": "Tải cho Mac →",
      "feature2.imageAlt": "Spotlight làm tối màn hình trừ vùng quanh con trỏ",

      "feature3.tag": "Chụp & chia sẻ",
      "feature3.title": "Bảng sạch, sẵn sàng chia sẻ",
      "feature3.body":
        "Chuyển sang bảng trắng để giải thích không bị xao nhãng, rồi xuất đúng những gì bạn thấy dưới dạng PNG hoặc SVG — không kèm điều khiển của LocalInk.",
      "feature3.b1": "Bảng trắng với canvas riêng",
      "feature3.b2": "Xuất PNG và sao chép vào clipboard",
      "feature3.b3": "Xuất SVG vector cho tài liệu",
      "feature3.link": "Tải cho Mac →",
      "feature3.imageAlt": "Bảng trắng với các nét vẽ marker",

      "stats.eyebrow": "Nhỏ gọn có chủ đích",
      "stats.title": "Native, nhanh và yên tĩnh.",
      "stats.sub":
        "Không web runtime. Không dịch vụ chạy nền. Không cần cấu hình trước khi thuyết trình.",
      "stats.1": "Dung lượng tải",
      "stats.2": "Yêu cầu mạng",
      "stats.3": "Apple Silicon & Intel",
      "stats.4": "Phiên bản macOS",

      "demo.eyebrow": "Dùng thử",
      "demo.title": "Thanh công cụ, ngay trong trình duyệt.",
      "demo.sub":
        "Vẽ lên slide bên dưới. Ứng dụng thật hoạt động theo cách này trên mọi cửa sổ trên Mac.",
      "demo.toolbar": "Công cụ demo",
      "demo.pen": "Bút",
      "demo.arrow": "Mũi tên",
      "demo.rect": "Hình chữ nhật",
      "demo.ellipse": "Ellipse",
      "demo.highlighter": "Bút dạ quang",
      "demo.undo": "Hoàn tác",
      "demo.clear": "Xóa",
      "demo.width": "Độ dày",
      "demo.canvas": "Demo vẽ tương tác",
      "demo.kicker": "DEMO SẢN PHẨM",
      "demo.slideTitle": "Nói đúng ý.<br />Giữ nhịp làm việc.",
      "demo.slideBody":
        "Vẽ ở bất kỳ đâu trên slide này. Các nút bên trên mô phỏng thanh công cụ nổi của LocalInk.",
      "demo.drawHere": "Vẽ tại đây",

      "color.red": "Đỏ",
      "color.orange": "Cam",
      "color.yellow": "Vàng",
      "color.green": "Lục",
      "color.blue": "Lam",
      "color.purple": "Tím",
      "color.white": "Trắng",
      "color.black": "Đen",

      "how.eyebrow": "Cách hoạt động",
      "how.title": "Ba bước. Không ngắt mạch.",
      "how.step1.title": "Mở và bắt đầu",
      "how.step1.body":
        "Mở LocalInk và bấm Bắt đầu vẽ, hoặc nhấn ⌃⌥D từ bất kỳ đâu.",
      "how.step2.title": "Vẽ và điều hướng",
      "how.step2.body":
        "Chú thích trên mọi ứng dụng. Bật vòng sáng hoặc spotlight để chỉ vào chi tiết mà không che giao diện.",
      "how.step3.title": "Quay lại công việc",
      "how.step3.body":
        "Tắt chế độ vẽ. Mọi cú bấm, kéo và cuộn lại thuộc về ứng dụng của bạn.",

      "privacy.eyebrow": "Riêng tư mặc định",
      "privacy.title": "Màn hình của bạn không bao giờ rời khỏi Mac.",
      "privacy.body":
        "LocalInk được xây dựng cho công việc nhạy cảm. Ứng dụng chạy hoàn toàn ngoại tuyến, không tài khoản và không analytics. Vẽ, vòng sáng và spotlight không cần quyền ghi màn hình; chỉ tính năng zoom và xuất ảnh tùy chọn mới cần.",
      "privacy.c1": "Không đăng ký, không thuê bao, không telemetry",
      "privacy.c2": "Không có mã mạng khi chạy",
      "privacy.c3": "Ảnh chỉ được lưu ở nơi bạn chọn",
      "privacy.c4": "Mã nguồn mở theo giấy phép MIT",
      "privacy.cloud": "Bảng trắng đám mây",
      "privacy.r1": "Hoạt động ngoại tuyến",
      "privacy.r2": "Yêu cầu tài khoản",
      "privacy.r3": "Chú thích trên mọi ứng dụng",
      "privacy.r4": "Dung lượng tải",
      "privacy.r5": "Pixel màn hình bị tải lên",
      "privacy.yes": "Có",
      "privacy.no": "Không",
      "privacy.never": "Không bao giờ",
      "privacy.rarely": "Hiếm khi",
      "privacy.usually": "Thường có",
      "privacy.often": "Thường xuyên",
      "privacy.browser": "Trong tab trình duyệt",
      "privacy.big": "100 MB+",

      "usecases.eyebrow": "Dành cho ai",
      "usecases.title": "Dành cho những người giải thích mọi thứ.",
      "usecases.1.title": "Giảng viên",
      "usecases.1.body":
        "Đánh dấu slide và code khi giảng bài, rồi trả lại quyền điều khiển mà không cần chuyển ứng dụng.",
      "usecases.2.title": "Người thuyết trình",
      "usecases.2.body":
        "Chỉ ra một nút trong demo trực tiếp và giữ khán giả đúng bước bạn muốn.",
      "usecases.3.title": "Nhà thiết kế",
      "usecases.3.body":
        "Khoanh một chi tiết khi review và chú thích trực tiếp trên giao diện đang thảo luận.",
      "usecases.4.title": "Hỗ trợ khách hàng",
      "usecases.4.body":
        "Hướng dẫn từng bước trên màn hình bằng dấu rõ ràng và con trỏ dễ thấy.",
      "usecases.5.title": "Nhà sáng tạo nội dung",
      "usecases.5.body":
        "Ghi tutorial có chú thích với lớp phủ native gọn gàng, không lọt vào khung hình.",
      "usecases.6.title": "Lập trình viên",
      "usecases.6.body":
        "Giải thích luồng code trong editor dùng chung, làm nổi bật một dòng log và zoom vào chi tiết nhỏ.",

      "download.eyebrow": "Tải xuống",
      "download.title": "Sẵn sàng khi bạn cần.",
      "download.sub": "Miễn phí mãi mãi. Không tài khoản. Không ràng buộc.",
      "download.zip": "Tải LocalInk.zip",
      "download.dmg": "Tải .dmg",
      "download.meta": "Phiên bản 1.0.2 · Universal · macOS 13 trở lên · ~0.6 MB",
      "download.installTitle": "Cài đặt",
      "download.install1": "Tải và giải nén LocalInk.zip.",
      "download.install2": "Kéo LocalInk.app vào Applications.",
      "download.install3": "Mở ứng dụng và bấm Bắt đầu vẽ.",
      "download.firstTitle": "Lần mở đầu tiên",
      "download.firstBody":
        "LocalInk chưa được notarize bằng tài khoản Apple Developer trả phí. Nếu macOS chặn lần mở đầu, vào System Settings → Privacy & Security → Open Anyway, hoặc chuột phải vào ứng dụng và chọn Open. Chỉ cần làm một lần.",
      "download.specific": "Muốn bản cụ thể?",
      "download.allReleases": "Xem tất cả bản phát hành trên GitHub",

      "faq.eyebrow": "Hỏi đáp",
      "faq.title": "Những điều cần biết.",
      "faq.q1": "LocalInk có thật sự miễn phí?",
      "faq.a1":
        "Có. Ứng dụng miễn phí và mã nguồn mở theo giấy phép MIT. Không có gói trả phí, tài khoản hay bản dùng thử.",
      "faq.q2": "Ứng dụng có thu thập dữ liệu không?",
      "faq.a2":
        "Không. Không telemetry, không analytics và không truy cập mạng trong ứng dụng. Nội dung màn hình của bạn không rời khỏi Mac.",
      "faq.q3": "Có cần quyền Ghi màn hình không?",
      "faq.a3":
        "Chỉ kính lúp, zoom toàn màn hình và xuất ảnh tùy chọn cần quyền này. Vẽ, vòng sáng và spotlight hoạt động mà không cần quyền chụp màn hình.",
      "faq.q4": "Tại sao macOS cảnh báo lần đầu?",
      "faq.a4":
        "Ứng dụng chưa được notarize bằng tài khoản Apple Developer trả phí. Vào System Settings → Privacy & Security → Open Anyway một lần, hoặc chuột phải vào ứng dụng và chọn Open.",
      "faq.q5": "Hỗ trợ những máy Mac nào?",
      "faq.a5":
        "macOS 13 trở lên, trên cả Mac Apple Silicon và Intel. Bản tải là universal.",
      "faq.q6": "Có dùng được khi chia sẻ màn hình không?",
      "faq.a6":
        "Có. Chia sẻ toàn bộ màn hình thường ghi lại lớp phủ chính xác. Chia sẻ một cửa sổ có thể không gồm lớp phủ, nên hãy kiểm tra trong ứng dụng họp hoặc ghi màn hình của bạn.",

      "footer.tagline":
        "Lớp chú thích màn hình native cho macOS, dành cho thuyết trình, giảng dạy và ghi màn hình.",
      "footer.product": "Sản phẩm",
      "footer.resources": "Tài nguyên",
      "footer.project": "Dự án",
      "footer.releases": "Bản phát hành",
      "footer.license": "Giấy phép MIT",
      "footer.issues": "Báo lỗi",
      "footer.changelog": "Nhật ký thay đổi",
      "footer.top": "Về đầu trang",
      "footer.made": "Thực hiện bởi Anh Nguyen (Jerry)",
      "footer.copy": "© 2026 LocalInk. Xây dựng bằng AppKit. Không cookie, không theo dõi."
    }
  };

  const languageKey = "localink-language";
  let currentLanguage = "en";

  function t(key) {
    const language = translations[currentLanguage] || translations.en;
    return language[key] ?? translations.en[key] ?? key;
  }

  function storedLanguage() {
    try {
      const requested = new URLSearchParams(window.location.search).get("lang");
      if (requested === "en" || requested === "vi") return requested;
    } catch (error) {
      /* URLSearchParams may be unavailable */
    }
    try {
      const saved = localStorage.getItem(languageKey);
      if (saved === "en" || saved === "vi") return saved;
    } catch (error) {
      /* storage may be unavailable */
    }
    return (navigator.language || "").toLowerCase().startsWith("vi") ? "vi" : "en";
  }

  const languageButtons = Array.from(document.querySelectorAll("[data-lang]"));

  function applyLanguage(language) {
    currentLanguage = language === "vi" ? "vi" : "en";
    document.documentElement.lang = currentLanguage;
    document.title = t("meta.title");

    const description = document.getElementById("metaDescription");
    if (description) description.setAttribute("content", t("meta.description"));
    const ogTitle = document.getElementById("ogTitle");
    if (ogTitle) ogTitle.setAttribute("content", t("meta.ogTitle"));
    const ogDescription = document.getElementById("ogDescription");
    if (ogDescription) ogDescription.setAttribute("content", t("meta.ogDescription"));

    document.querySelectorAll("[data-i18n]").forEach(function (element) {
      element.textContent = t(element.dataset.i18n);
    });
    document.querySelectorAll("[data-i18n-html]").forEach(function (element) {
      element.innerHTML = t(element.dataset.i18nHtml);
    });
    document.querySelectorAll("[data-i18n-title]").forEach(function (element) {
      element.setAttribute("title", t(element.dataset.i18nTitle));
    });
    document.querySelectorAll("[data-i18n-aria-label]").forEach(function (element) {
      element.setAttribute("aria-label", t(element.dataset.i18nAriaLabel));
    });
    document.querySelectorAll("[data-i18n-alt]").forEach(function (element) {
      element.setAttribute("alt", t(element.dataset.i18nAlt));
    });

    document.querySelectorAll(".swatch[data-color-key]").forEach(function (swatch) {
      swatch.setAttribute("aria-label", t("color." + swatch.dataset.colorKey));
    });

    languageButtons.forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.dataset.lang === currentLanguage));
    });

    const navToggle = document.getElementById("navToggle");
    if (navToggle) {
      const open = navToggle.getAttribute("aria-expanded") === "true";
      navToggle.setAttribute("aria-label", t(open ? "nav.close" : "nav.menu"));
    }

    try {
      localStorage.setItem(languageKey, currentLanguage);
    } catch (error) {
      /* storage may be unavailable */
    }
  }

  languageButtons.forEach(function (button) {
    button.addEventListener("click", function () {
      applyLanguage(button.dataset.lang);
    });
  });

  /* ------------------------------------------------------------------ */
  /* Navigation                                                         */
  /* ------------------------------------------------------------------ */

  const header = document.getElementById("nav");
  const navToggle = document.getElementById("navToggle");
  const navLinks = document.getElementById("navLinks");

  function onScroll() {
    if (header) header.classList.toggle("scrolled", window.scrollY > 6);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  if (navToggle && navLinks) {
    function closeMenu() {
      header.classList.remove("open");
      navLinks.classList.remove("open");
      navToggle.setAttribute("aria-expanded", "false");
      navToggle.setAttribute("aria-label", t("nav.menu"));
    }

    navToggle.addEventListener("click", function () {
      const open = !navLinks.classList.contains("open");
      header.classList.toggle("open", open);
      navLinks.classList.toggle("open", open);
      navToggle.setAttribute("aria-expanded", String(open));
      navToggle.setAttribute("aria-label", t(open ? "nav.close" : "nav.menu"));
    });

    navLinks.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", closeMenu);
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > 860) closeMenu();
    });
  }

  /* ------------------------------------------------------------------ */
  /* Reveal                                                             */
  /* ------------------------------------------------------------------ */

  const reveals = Array.from(document.querySelectorAll(".reveal"));

  function revealNow(element) {
    element.classList.add("in");
  }

  reveals.forEach(function (element) {
    const rect = element.getBoundingClientRect();
    if (rect.top < window.innerHeight * 0.96 && rect.bottom > 0) revealNow(element);
  });

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          revealNow(entry.target);
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.06, rootMargin: "0px 0px -24px 0px" });
    reveals.forEach(function (element) { observer.observe(element); });
  } else {
    reveals.forEach(revealNow);
  }

  window.setTimeout(function () { reveals.forEach(revealNow); }, 1800);

  /* ------------------------------------------------------------------ */
  /* Interactive demo                                                   */
  /* ------------------------------------------------------------------ */

  const canvas = document.getElementById("demoCanvas");

  if (canvas) {
    const wrap = document.getElementById("canvasWrap");
    const ctx = canvas.getContext("2d");
    const swatchWrap = document.getElementById("swatches");
    const widthInput = document.getElementById("demoWidth");
    const undoButton = document.getElementById("demoUndo");
    const clearButton = document.getElementById("demoClear");
    const hint = document.getElementById("demoHint");
    const toolButtons = Array.from(document.querySelectorAll(".tool[data-tool]"));

    const palette = [
      { key: "red", value: "#f24436" },
      { key: "orange", value: "#ff9400" },
      { key: "yellow", value: "#ffd91a" },
      { key: "green", value: "#33c759" },
      { key: "blue", value: "#2196f3" },
      { key: "purple", value: "#9c59f2" },
      { key: "white", value: "#ffffff" },
      { key: "black", value: "#1a1a1a" }
    ];

    let tool = "pen";
    let color = palette[0].value;
    let lineWidth = 5;
    let marks = [];
    let current = null;
    let drawing = false;
    let dpr = Math.min(window.devicePixelRatio || 1, 2);

    function resize() {
      if (!wrap) return;
      const rect = wrap.getBoundingClientRect();
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.max(1, Math.round(rect.width * dpr));
      canvas.height = Math.max(1, Math.round(rect.height * dpr));
      canvas.style.width = rect.width + "px";
      canvas.style.height = rect.height + "px";
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      redraw();
    }

    function buildSwatches() {
      if (!swatchWrap) return;
      palette.forEach(function (entry, index) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "swatch" + (index === 0 ? " active" : "");
        button.style.background = entry.value;
        button.dataset.colorKey = entry.key;
        button.setAttribute("aria-label", t("color." + entry.key));
        button.addEventListener("click", function () {
          color = entry.value;
          swatchWrap.querySelectorAll(".swatch").forEach(function (swatch) {
            swatch.classList.remove("active");
          });
          button.classList.add("active");
        });
        swatchWrap.appendChild(button);
      });
    }

    function drawMark(mark) {
      const isHighlighter = mark.tool === "highlighter";
      ctx.save();
      ctx.lineCap = "round";
      ctx.lineJoin = "round";
      ctx.strokeStyle = mark.color;
      ctx.fillStyle = mark.color;
      ctx.lineWidth = isHighlighter ? mark.width * 2.6 : mark.width;
      ctx.globalAlpha = isHighlighter ? 0.35 : 1;

      if (mark.tool === "pen" || isHighlighter) {
        if (mark.points.length < 2) {
          ctx.beginPath();
          ctx.arc(mark.points[0].x, mark.points[0].y, ctx.lineWidth / 2, 0, Math.PI * 2);
          ctx.fill();
        } else {
          ctx.beginPath();
          ctx.moveTo(mark.points[0].x, mark.points[0].y);
          for (let i = 1; i < mark.points.length; i += 1) {
            ctx.lineTo(mark.points[i].x, mark.points[i].y);
          }
          ctx.stroke();
        }
      } else if (mark.tool === "arrow") {
        const start = mark.start;
        const end = mark.end;
        ctx.beginPath();
        ctx.moveTo(start.x, start.y);
        ctx.lineTo(end.x, end.y);
        ctx.stroke();
        const angle = Math.atan2(end.y - start.y, end.x - start.x);
        const size = Math.max(14, mark.width * 3.6);
        const wing = Math.PI / 6;
        ctx.beginPath();
        ctx.moveTo(end.x, end.y);
        ctx.lineTo(end.x - size * Math.cos(angle - wing), end.y - size * Math.sin(angle - wing));
        ctx.lineTo(end.x - size * Math.cos(angle + wing), end.y - size * Math.sin(angle + wing));
        ctx.closePath();
        ctx.fill();
      } else if (mark.tool === "rect") {
        const x = Math.min(mark.start.x, mark.end.x);
        const y = Math.min(mark.start.y, mark.end.y);
        const width = Math.abs(mark.end.x - mark.start.x);
        const height = Math.abs(mark.end.y - mark.start.y);
        ctx.strokeRect(x, y, width, height);
      } else if (mark.tool === "ellipse") {
        const cx = (mark.start.x + mark.end.x) / 2;
        const cy = (mark.start.y + mark.end.y) / 2;
        const rx = Math.abs(mark.end.x - mark.start.x) / 2;
        const ry = Math.abs(mark.end.y - mark.start.y) / 2;
        ctx.beginPath();
        ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2);
        ctx.stroke();
      }
      ctx.restore();
    }

    function redraw() {
      const rect = wrap.getBoundingClientRect();
      ctx.clearRect(0, 0, rect.width, rect.height);
      marks.forEach(drawMark);
      if (current) drawMark(current);
    }

    function position(event) {
      const rect = canvas.getBoundingClientRect();
      return { x: event.clientX - rect.left, y: event.clientY - rect.top };
    }

    canvas.addEventListener("pointerdown", function (event) {
      event.preventDefault();
      canvas.setPointerCapture(event.pointerId);
      const point = position(event);
      if (hint) hint.classList.add("hide");
      current = {
        tool: tool,
        color: color,
        width: lineWidth,
        points: [point],
        start: point,
        end: point
      };
      drawing = true;
      if (tool === "pen" || tool === "highlighter") redraw();
    });

    canvas.addEventListener("pointermove", function (event) {
      if (!drawing || !current) return;
      const point = position(event);
      current.end = point;
      if (current.tool === "pen" || current.tool === "highlighter") {
        current.points.push(point);
      }
      redraw();
    });

    function finish() {
      if (!current) {
        drawing = false;
        return;
      }
      const mark = current;
      const isShape = mark.tool === "rect" || mark.tool === "ellipse" || mark.tool === "arrow";
      const tooSmall =
        isShape &&
        Math.abs(mark.end.x - mark.start.x) < 3 &&
        Math.abs(mark.end.y - mark.start.y) < 3;

      if (!tooSmall) {
        if (mark.tool === "pen" || mark.tool === "highlighter") {
          if (mark.points.length > 1) marks.push(mark);
        } else {
          marks.push(mark);
        }
      }
      current = null;
      drawing = false;
      redraw();
    }

    canvas.addEventListener("pointerup", finish);
    canvas.addEventListener("pointercancel", finish);
    canvas.addEventListener("pointerleave", function () {
      if (drawing) finish();
    });

    toolButtons.forEach(function (button) {
      button.addEventListener("click", function () {
        tool = button.getAttribute("data-tool");
        toolButtons.forEach(function (item) { item.classList.remove("active"); });
        button.classList.add("active");
      });
    });

    if (widthInput) {
      widthInput.addEventListener("input", function () {
        lineWidth = Number(widthInput.value);
      });
    }

    if (undoButton) {
      undoButton.addEventListener("click", function () {
        marks.pop();
        redraw();
      });
    }

    if (clearButton) {
      clearButton.addEventListener("click", function () {
        marks = [];
        current = null;
        redraw();
      });
    }

    buildSwatches();
    resize();

    if ("ResizeObserver" in window && wrap) {
      new ResizeObserver(resize).observe(wrap);
    } else {
      window.addEventListener("resize", resize);
    }
  }

  /* ------------------------------------------------------------------ */
  /* Boot                                                               */
  /* ------------------------------------------------------------------ */

  const year = document.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());

  const heroVideo = document.querySelector(".hero-video");
  if (heroVideo && window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    heroVideo.pause();
  }

  applyLanguage(storedLanguage());
})();
