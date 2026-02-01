uniffi::setup_scaffolding!();

#[uniffi::export]
fn say_hi() -> String {
    "Hello from Rust!".to_string()
}

#[uniffi::export]
fn greet(name: String) -> String {
    format!("Hello, {name} from Rust!")
}

#[uniffi::export]
fn compute_example(x: i32) -> String {
    let y = x * 2 + 1;
    format!("Rust computed: {x} -> {y}")
}


#[uniffi::export]
pub fn count_primes(limit: i32) -> i32 {
    if limit < 2 {
        return 0;
    }

    let n = limit as usize;
    let mut is_prime = vec![true; n + 1];

    let cap_bits = is_prime.capacity();
    let approx_bytes = (cap_bits + 7) / 8;
    println!(
        "count_primes: n={} len(bits)={} cap(bits)={} approx_cap_bytes={} (~{:.2} MB)",
        n,
        is_prime.len(),
        cap_bits,
        approx_bytes,
        approx_bytes as f64 / (1024.0 * 1024.0),
    );

    is_prime[0] = false;
    is_prime[1] = false;

    let mut p = 2usize;
    while p * p <= n {
        if is_prime[p] {
            let mut multiple = p * p;
            while multiple <= n {
                is_prime[multiple] = false;
                multiple += p;
            }
        }
        p += 1;
    }

    is_prime.iter().filter(|&&b| b).count() as i32
}

fn main() {
    uniffi::uniffi_bindgen_main()
}
