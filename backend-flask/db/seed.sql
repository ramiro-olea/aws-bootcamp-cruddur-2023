-- this file was manually created
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Ramiro Olea','ramolea','ror5687@hotmail.com' ,'97923303-18eb-4faa-b62b-e015405d194b'),
  ('Andrew Bayko','bayko','bayko@exampro.co' ,'MOCK'),
  ('Londo Mollari','londo','lmollari@centari.com' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'ramolea' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )