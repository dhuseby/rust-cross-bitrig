sh install.sh

mkdir target

rustc --target x86_64-pc-freebsd-elf --crate-type lib src/my.rs -o target/libmy.rlib
rustc --target x86_64-pc-freebsd-elf --emit obj -L . src/main.rs -o target/main.o


clang \
 -L./df-tree/usr/lib \
 -L./df-tree/usr/lib/gcc47 \
 -B./df-tree/usr/lib \
 -B./df-tree/usr/lib/gcc47 \
 -target x86_64-unknown-dragonfly \
 -o target/app target/main.o ./rust-nightly/src/rt/arch/x86_64/morestack.S target/libmy.rlib
