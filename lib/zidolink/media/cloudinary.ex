defmodule Zidolink.Media.Cloudinary do
  @moduledoc "Uploads files to Cloudinary via an unsigned preset."

  def upload(file_path, original_filename) do
    cloud_name = System.get_env("CLOUDINARY_CLOUD_NAME")
    upload_preset = System.get_env("CLOUDINARY_UPLOAD_PRESET")
    file_binary = File.read!(file_path)

    case Req.post("https://api.cloudinary.com/v1_1/#{cloud_name}/auto/upload",
           form_multipart: [
             file: {file_binary, filename: original_filename},
             upload_preset: upload_preset
           ]
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end
end
