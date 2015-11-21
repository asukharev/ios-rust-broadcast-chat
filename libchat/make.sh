cargo build --target=i386-apple-ios --release
cargo build --target x86_64-apple-ios --release
lipo -create ./target/x86_64-apple-ios/release/libchat.a ./target/i386-apple-ios/release/libchat.a -o ./target/libchat.a
cp ./src/chat.h ./target/
# strip ./target/libchat.a
