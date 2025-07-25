(*
 *   InstantObjects
 *   JSON Support
 *)

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 2.0
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is: Carlo Barazzetta
 *
 * The Initial Developer of the Original Code is: Carlo Barazzetta
 *
 * Contributor(s):
 * Adrea Petrelli, Nando Dessena, Marco Cant�
 *
 * ***** END LICENSE BLOCK ***** *)

unit InstantJSONReg;

{$IFDEF LINUX64}
{$I '../../InstantDefines.inc'}
{$ELSE}
{$I '..\..\InstantDefines.inc'}
{$ENDIF}

interface

procedure Register;

implementation

uses
  System.Classes, InstantJSON;
  
procedure Register;
begin
  RegisterComponents('InstantObjects', [TInstantJSONConnector]);
  RegisterComponents('InstantObjects', [TJSONFilesAccessor]);
end;

end.
