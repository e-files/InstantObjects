(*
 *   InstantObjects DBEvolver Support
 *   JSON Catalog
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
 * The Original Code is: InstantObjects DBEvolver Support/JSON Catalog
 *
 * The Initial Developer of the Original Code is: Steven Mitchell
 *
 * Portions created by the Initial Developer are Copyright (C) 2005
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

unit InstantJSONCatalog;

{$IFDEF LINUX64}
{$I '../../InstantDefines.inc'}
{$ELSE}
{$I '..\..\InstantDefines.inc'}
{$ENDIF}

{$IFDEF D6+}
{$WARN UNIT_PLATFORM OFF}
{$ENDIF}

interface

uses
{$IFNDEF IO_CONSOLE}
  Vcl.FileCtrl,
{$ENDIF}
  InstantPersistence, InstantBrokers, InstantMetadata, InstantTypes;

type
  // A TInstantCatalog that reads catalog information from a JSON
  // database. Can be used with a JSON broker.
  TInstantJSONCatalog = class(TInstantBrokerCatalog)
  private
    procedure AddTableMetadatas(TableMetadatas: TInstantTableMetadatas);
  protected
    function GetFeatures: TInstantCatalogFeatures; override;
  public
    procedure InitTableMetadatas(ATableMetadatas: TInstantTableMetadatas);
      override;
  end;

implementation

uses
  System.SysUtils
  , System.Classes
  , System.TypInfo
  , InstantConsts;
  
procedure TInstantJSONCatalog.AddTableMetadatas(
  TableMetadatas: TInstantTableMetadatas);
var
  vDatabaseName: String;
  i: integer;
  TableMetadata: TInstantTableMetadata;
  vTables: TStringList;

  procedure GetTablesList(const ADatabaseName: string; ATables: TStrings);
  var
    sr: TSearchRec;
  begin
    if FindFirst(ADatabaseName + '*', faDirectory, sr) = 0 then
      repeat
        if ((sr.Attr and faDirectory) <> 0) and
                (sr.Name <> '.') and (sr.Name <> '..') then
          ATables.Add(sr.Name);
      until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  
begin
  vTables := TStringList.Create;
  try
    vDatabaseName := Broker.Connector.DatabaseName;
    if DirectoryExists(vDatabaseName) then
      GetTablesList(vDatabaseName, vTables);

    if vTables.Count > 0 then
      for i := 0 to Pred(vTables.Count) do
      begin
        TableMetadata := TableMetadatas.Add;
        TableMetadata.Name := vTables[i];
      end;
  finally
    vTables.Free;
  end;
end;

function TInstantJSONCatalog.GetFeatures: TInstantCatalogFeatures;
begin
  Result := [cfReadTableInfo];
end;

procedure TInstantJSONCatalog.InitTableMetadatas(
  ATableMetadatas: TInstantTableMetadatas);
begin
  ATableMetadatas.Clear;
  AddTableMetadatas(ATableMetadatas);
end;

end. 
