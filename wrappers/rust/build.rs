use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let native_dir = manifest_dir
        .parent()
        .and_then(|p| p.parent())
        .expect("manifest directory layout")
        .join("librangemap")
        .join("native");

    println!("cargo:rustc-link-search=native={}", native_dir.display());
    println!("cargo:rustc-link-lib=dylib=librangemap_core");
    println!("cargo:rerun-if-changed=build.rs");
}
