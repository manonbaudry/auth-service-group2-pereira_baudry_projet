(* This Source Code Form is subject to the terms of the Mozilla Public License,
      v. 2.0. If a copy of the MPL was not distributed with this file, You can
      obtain one at https://mozilla.org/MPL/2.0/ *)
open Util
module D = Domain
module E = Infra.Environment

module Jwt = struct
  let verify jwt = Jwto.decode_and_verify E.jwt_secret jwt

  let verify_and_get_iss jwt =
    let open ResultSyntax in
    let* decoded = verify jwt in
    let payload = Jwto.get_payload decoded in
    let iss =
      Option.fold ~none:"" ~some:(fun x -> x) @@ Jwto.get_claim "iss" payload
    and exp =
      Option.fold ~none:"" ~some:(fun x -> x) @@ Jwto.get_claim "exp" payload
    and sub =
      Option.fold ~none:"" ~some:(fun x -> x) @@ Jwto.get_claim "sub" payload
    in
    let exp_float =
      Option.fold ~none:0. ~some:(fun x -> x) @@ float_of_string_opt exp in
    if iss = E.app_name && exp_float > Unix.time () then
      Ok sub
    else
      Error "Invalid token"

  let verify_and_get_role jwt =
    let open ResultSyntax in
    let* decoded = verify jwt in
    let payload = Jwto.get_payload decoded in
    let iss =
      Option.fold ~none:"" ~some:(fun x -> x) @@ Jwto.get_claim "iss" payload
    and exp =
      Option.fold ~none:"" ~some:(fun x -> x) @@ Jwto.get_claim "exp" payload
    and role =
      Option.fold ~none:"" ~some:(fun x -> x) @@ Jwto.get_claim "role" payload
    in
    let exp_float =
      Option.fold ~none:0. ~some:(fun x -> x) @@ float_of_string_opt exp in
    if iss = E.app_name && exp_float > Unix.time () then
      Ok role
    else
      Error "Invalid token"

  let days_to_timestamp x = x *. 86400.

  let from_member member =
    let payload =
      let iat = Unix.time () in
      [
        ("sub", D.Member.id member |> D.Uuid.show);
        ("iss", E.app_name);
        ("iat", iat |> int_of_float |> string_of_int);
        ("exp", iat +. days_to_timestamp 3. |> int_of_float |> string_of_int);
        ("role", D.Member.role member);
      ] in
    Jwto.encode Jwto.HS512 E.jwt_secret payload
end


module Member (MemberRepository : Repository.MEMBER) = struct
  let signup ~email ~password connection =
    let id = D.Uuid.v4_gen E.random_seed () in
    let hash = D.Hash.make ~seed:E.hash_seed password in
    match D.Email.make email with
    | Error e -> Lwt.return_error @@ "Invalid email: " ^ email
    | Ok member_email -> (
      let open Lwt in
      let role = "member" in
      MemberRepository.create ~id ~email:member_email ~role ~hash connection
      >>= function
      | Ok db_result -> Lwt.return_ok ()
      | Error _ -> Lwt.return_error "Unable to create")


  let signin ~email ~password connection =
    let hash = D.Hash.make ~seed:E.hash_seed password in
    match D.Email.make email with
    | Error e -> Lwt.return_error @@ "Invalid email: " ^ email
    | Ok member_email -> (
      let open Lwt in
      MemberRepository.get_by_email_hash ~email:member_email ~hash connection
      >|= function
      | Ok db_result -> Jwt.from_member db_result
      | Error _ -> Error "Wrong email or password")


  let get_by_id ~id connection =
    match D.Uuid.make id with
    | Error e -> Lwt.return_error @@ "Invalid id: " ^ id
    | Ok member_id ->
      let open Lwt in
      MemberRepository.get_by_id ~id:member_id connection
      >>= function
      | Ok db_result -> Lwt.return_ok (D.Member.show db_result)
      | Error _ -> Lwt.return_error "Unable to retrive a member from this id"


  let update ~id ~email ~username ~password connection =
    let hash = D.Hash.make ~seed:E.hash_seed password in
    match D.Email.make email with
    | Error e -> Lwt.return_error @@ "Invalid email: " ^ email
    | Ok member_email ->
      match D.Uuid.make id with
      | Error e -> Lwt.return_error @@ "Invalid id: " ^ id
      | Ok member_id ->
        let open Lwt in
        MemberRepository.update ~id:member_id ~email:member_email ~username ~hash connection
        >>= function
        | Ok db_result -> Lwt.return_ok ()
        | Error _ -> Lwt.return_error "Unable to update the member"
  
    
  let delete ~id connection =
    match D.Uuid.make id with
    | Error e -> Lwt.return_error @@ "Invalid id: " ^ id
    | Ok member_id ->
      let open Lwt in
      MemberRepository.delete ~id:member_id connection
      >>= function
      | Ok db_result -> Lwt.return_ok ()
      | Error _ -> Lwt.return_error "Unable to delete a member from this id"

end
