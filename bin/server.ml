(* This Source Code Form is subject to the terms of the Mozilla Public License,
      v. 2.0. If a copy of the MPL was not distributed with this file, You can
      obtain one at https://mozilla.org/MPL/2.0/ *)
module E = Auth_lib.Infra.Environment
module A = Auth_lib.Api
module R = Auth_lib.Rabbit

let () =
  let () = Dream.initialize_log ~level:E.log_level () in
  let mutex = Lwt_mutex.create () in
  let _ = R.run (R.handler mutex) () in
  Dream.run ~port:E.port
  @@ Dream.logger
  @@ Dream.sql_pool ~size:3 E.db_uri
  @@ Dream.router A.routes
