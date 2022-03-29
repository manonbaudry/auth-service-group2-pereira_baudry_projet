open Util
open Amqp_client_lwt
open Infra.Log

module JwtService = Service.Jwt

let host = "parrow-01.rmq.cloudamqp.com"

let credentials = ("pymgrgko", "1rBW0EAK9jf1IGMVKnKJcy5N_daFPPBZ")

let virtual_host = "pymgrgko"

let client : Rpc.Client.t option ref = ref None

let get_connection () =
  Connection.connect ~id:"auth-job" ~virtual_host:virtual_host ~credentials:credentials host

let get_channel connection =
  Connection.open_channel ~id:"auth-job"  Channel.with_confirm connection

let get_queue channel =
  Queue.declare channel "auth-job"


let handler m (h, s) =
  let open LwtSyntax in
  let () = print_endline "Parse message here" in
  let* () = Lwt_mutex.lock m in
  let () = print_endline "Process msg here" in
  let verify_and_get_role_result = JwtService.verify_and_get_role s in
  let _ = Lwt_mutex.unlock m in
  match verify_and_get_role_result with
  | Error e -> Lwt.return (h, "error")
  | Ok role ->
    Lwt.return (h, role)



let run handler () =
  let open LwtSyntax in
  let* connection = get_connection () in 
  let () = info "AMQP Connection started" in
  let* channel = get_channel connection in
  let () = info "AMQP Channel opened" in
  let* queue = get_queue channel in 
  let () = info "AMQP Listening for requests" in
  let* server = Rpc.Server.start channel queue handler in 
  Lwt.return (queue,channel)