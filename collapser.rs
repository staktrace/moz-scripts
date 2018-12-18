use std::env;
use std::fs::File;
use std::io::BufRead;
use std::io::BufReader;
use std::iter::FromIterator;
use std::vec::Vec;

fn flip(token: &str) -> String {
    if token == "(bits == 32)" {
        "(bits == 64)".to_string()
    } else if token == "(bits == 64)" {
        "(bits == 32)".to_string()
    } else if token == "(processor == \"x86\")" {
        "(processor == \"x86_64\")".to_string()
    } else if token == "(processor == \"x86_64\")" {
        "(processor == \"x86\")".to_string()
    } else if token.find("not ") == Some(0) {
        token[4..].to_string()
    } else {
        "not ".to_string() + token
    }
}

fn try_collapse(a: &Vec<String>, b: &Vec<String>) -> Option<Vec<String>> {
    //eprintln!("Comparing {:?} and {:?}", a, b);
    let mut flipped = false;
    let mut result = Vec::new();
    for tok in a {
        if b.contains(tok) {
            //eprintln!("Token match {}", tok);
            result.push(tok.clone());
        } else if !flipped && b.contains(&flip(tok)) {
            //eprintln!("Flipped {}", tok);
            flipped = true;
        } else {
            //eprintln!("Token mismatch {}", tok);
            return None;
        }
    }
    Some(result)
}

fn collapse(tokensets: &mut Vec<Vec<String>>) {
    let mut changed = false;
    loop {
        'outer: for i in 0..tokensets.len() {
            for j in 0..i {
                if tokensets[i].len() != tokensets[j].len() {
                    continue;
                }
                if let Some(set) = try_collapse(&tokensets[i], &tokensets[j]) {
                    tokensets[j] = set;
                    tokensets.remove(i);
                    changed = true;
                    break 'outer;
                }
            }
        }
        if !changed {
            break;
        }
        changed = false;
    }
}

fn emit(tokensets: &Vec<Vec<String>>, set_prefix: &Option<String>, set_suffix: &Option<String>) {
    for set in tokensets {
        let combined = Vec::from_iter(set.iter().map(|s| s.clone())).join(" and ");
        println!("{}{}{}",
                 set_prefix.as_ref().unwrap(),
                 combined,
                 set_suffix.as_ref().unwrap());
    }
}
fn main() {
    let file = File::open(env::args().skip(1).next().unwrap()).unwrap();
    let reader = BufReader::new(&file);
    let mut tokensets : Vec<Vec<String>> = Vec::new();
    let mut set_prefix = None;
    let mut set_suffix = None;
    for line in reader.lines() {
        let line = line.unwrap();
        let prefix = line.find("if ").map(|ix| line[0..ix + 3].to_string());
        let suffix = line.rfind(':').map(|ix| line[ix..].to_string());
        let part_of_set = match (&set_prefix, &prefix) {
            (&Some(ref x), &Some(ref y)) if x != y => false,
            (_, &None) => false,
            _ => true,
        } && match (&set_suffix, &suffix) {
            (&Some(ref x), &Some(ref y)) if x != y => false,
            (_, &None) => false,
            _ => true,
        };

        if !part_of_set && tokensets.len() > 0 {
            collapse(&mut tokensets);
            emit(&tokensets, &set_prefix, &set_suffix);
            tokensets.clear();
        }

        if line.trim_left().starts_with("if ") {
            set_prefix = prefix;
            set_suffix = suffix;
            let prefix_len = set_prefix.as_ref().unwrap().len();
            let suffix_len = set_suffix.as_ref().unwrap().len();
            let tokens = line[prefix_len .. line.len() - suffix_len].split(" and ").map(String::from).collect();
            //eprintln!("Collecting tokenset {:?}", tokens);
            tokensets.push(tokens);
            continue;
        } else {
            println!("{}", line);
        }
    }
    if tokensets.len() > 0 {
        collapse(&mut tokensets);
        emit(&tokensets, &set_prefix, &set_suffix);
    }
}
