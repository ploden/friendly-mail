// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "friendly_mail_core",
    platforms: [
        .iOS("14.0"),
        //.macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "friendly_mail_core",
            targets: ["friendly_mail_core"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "friendly_mail_core",
            dependencies: [],
            resources: [
                .copy("friendly_mail_core_resources/Templates/victor"),
                /*
                .copy("Templates/birdie/txt/new_like_notification_subject_template.txt"),
                .copy("Templates/birdie/html/new_like_notification_template_working.html"),
                .copy("Templates/birdie/txt/new_like_notification_template.txt"),
                .copy("Templates/birdie/txt/signature_template.txt"),
                .copy("Templates/default/txt/invite_subject_template.txt"),
                .copy("Templates/birdie/txt/like_notification_template.txt"),
                .copy("Templates/default/html/decode_quoted_printable.py"),
                //.copy("Templates/birdie/html/decode_quoted_printable.py"),
                .copy("Templates/default/html/new_post_sample_decoded.html"),
                .copy("Templates/birdie/html/footer.html"),
                .copy("Templates/default/txt/new_comment_notification_template.txt"),
                .copy("Templates/default/html/new_post_notification_template.html"),
                .copy("Templates/default/html/replied_to_tweet_decoded.html"),
                .copy("Templates/birdie/html/new_post_notification_sample.html"),
                 */
            ]
        ),
        .testTarget(
            name: "friendly_mail_coreTests",
            dependencies: [
                "friendly_mail_core",
            ]),
    ]
)
