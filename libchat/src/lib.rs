#![allow(dead_code)]
#![feature(convert)]

extern crate net2;
use net2::{UdpSocketExt};

use std::net::{UdpSocket, SocketAddrV4, Ipv4Addr};
use std::str;

extern {
   fn trigger_callback(data: &[u8], size: usize);
}

#[no_mangle]
pub extern fn start_server() {
    let listen_addr = {
        let ip = Ipv4Addr::new(0,0,0,0);
        SocketAddrV4::new(ip, 54321)
    };

    let recv_socket = {
        match UdpSocket::bind(listen_addr) {
            Ok(s) => s,
            Err(why) => panic!("{:?}", why)
        }
    };

    loop {
        let mut buf = [0; 512];
        let (_, _) = match recv_socket.recv_from(&mut buf) {
            Ok((size, soket)) => {
                unsafe {
                    trigger_callback(&buf[..size], size);
                }
                (size, soket)
            },
            Err(why) => panic!("{:?}", why)
        };
    }

    // drop(recv_socket);
}

#[no_mangle]
pub extern fn send_data(data: &[u8], broadcast: &[u8]) {
    // let target_addr = {
    //     let ip = Ipv4Addr::new(192,168,251,255);
    //     SocketAddrV4::new(ip,54321)
    // };
    let listen_addr = {
        let ip = Ipv4Addr::new(0,0,0,0);
        SocketAddrV4::new(ip, 54322)
    };
    let target_addr = match str::from_utf8(broadcast) {
        Ok(v) => format!("{}:{:?}", v, 54321),
        Err(e) => panic!("Invalid UTF-8 sequence: {}", e),
    };

    let sender_socket = {
        match UdpSocket::bind(listen_addr) {
            Ok(s) => {
                match s.set_broadcast(true) {
                    Ok(_) => s,
                    Err(why) => panic!(why)
                }
            },
            Err(why) => panic!("{:?}", why)
        }
    };
    println!("send_to {:?}: {:?}", target_addr, data);
    let result = sender_socket.send_to(&data, target_addr.as_str());
    match result {
        Ok(_) => (),
        Err(err) => panic!("Write error: {}", err)
    }
    drop(sender_socket);
}
