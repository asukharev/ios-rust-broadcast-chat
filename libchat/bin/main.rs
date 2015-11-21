// nc -l -u -k 54321
// echo "Hello" | socat - udp-datagram:192.168.1.255:54321,broadcast

extern crate chat;
use std::io::{self, BufRead};
use std::thread;

fn main() {
    thread::spawn(move || {
        chat::start_server();
    });

    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        match line {
            Ok(l) => {
                let b: Vec<u8> = l.bytes().collect();
                let c: &[u8] = &b[..];
                chat::send_data(c)
            },
            Err(why) => panic!(why)
        }
    }
}
