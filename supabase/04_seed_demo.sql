with admin_user as (
  select id from public.profiles where role = 'admin' order by created_at limit 1
)
insert into public.venues
  (owner_id, status, category, name, city, address, is_indoor, field_count,
   price_per_hour, open_hour, close_hour, facilities, description, image_url,
   class_start_slots, accepting_bookings)
select a.id, 'disetujui', v.category, v.name, v.city, v.address, v.is_indoor,
       v.field_count, v.price_per_hour, v.open_hour, v.close_hour, v.facilities,
       v.description, v.image_url, v.class_start_slots, v.accepting_bookings
from admin_user a
cross join (values
  ('Lapangan', 'Smash Padel Club', 'Jakarta Utara', 'Pantai Indah Kapuk', true, 3, 180000, 6, 23,
   array['Parkir','Toilet','Kantin','AC','Loker','Wifi']::text[],
   'Lapangan padel indoor dengan permukaan rumput sintetis standar internasional. Dilengkapi pencahayaan LED dan sirkulasi udara yang nyaman untuk bermain siang maupun malam hari.',
   'https://images.unsplash.com/photo-1658491830143-72808ca237e3?q=80&w=1073&auto=format&fit=crop',
   '{}'::int[], true),
  ('Lapangan', 'Arena Padel BSD', 'Tangerang Selatan', 'BSD City', false, 3, 150000, 6, 22,
   array['Parkir','Toilet','Kantin','Mushola']::text[],
   'Lapangan outdoor dengan suasana terbuka dan udara segar, cocok untuk bermain di pagi atau sore hari. Dikelilingi taman kecil yang membuat suasana lebih santai.',
   'https://plus.unsplash.com/premium_photo-1708692919464-b5608dd10542?q=80&w=1170&auto=format&fit=crop',
   '{}'::int[], true),
  ('Lapangan', 'Padel House Kemang', 'Jakarta Selatan', 'Kemang', true, 4, 220000, 7, 23,
   array['Parkir','Toilet','Kantin','AC','Loker','Shower','Wifi']::text[],
   'Venue premium di tengah kawasan Kemang dengan 4 lapangan indoor full AC. Sering digunakan untuk turnamen komunitas dan kelas latihan bersama pelatih bersertifikat.',
   'https://plus.unsplash.com/premium_photo-1755813486079-9997d76a897d?q=80&w=1170&auto=format&fit=crop',
   '{}'::int[], false),
  ('Lapangan', 'Padel Point Kelapa Gading', 'Jakarta Utara', 'Kelapa Gading', true, 2, 160000, 8, 22,
   array['Parkir','Toilet','AC','Loker']::text[],
   'Lapangan indoor dengan 2 court yang nyaman untuk pemain pemula maupun menengah. Tersedia penyewaan raket dan bola bagi yang belum punya perlengkapan sendiri.',
   'https://plus.unsplash.com/premium_photo-1768803218089-9f2a9716f7e6?q=80&w=1171&auto=format&fit=crop',
   '{}'::int[], true),
  ('Lapangan', 'Elite Padel Center', 'Tangerang Selatan', 'Bintaro', false, 3, 200000, 6, 23,
   array['Parkir','Toilet','Kantin','Mushola','Wifi']::text[],
   'Kompleks olahraga dengan 3 lapangan outdoor berstandar kompetisi. Terdapat tribun kecil untuk penonton dan area tunggu yang teduh.',
   'https://plus.unsplash.com/premium_photo-1768960235027-7553218f1303?q=80&w=1312&auto=format&fit=crop',
   '{}'::int[], true),
  ('Lapangan', 'GOR Padel Senayan', 'Jakarta Pusat', 'Senayan', true, 3, 190000, 6, 22,
   array['Parkir','Toilet','Kantin','AC']::text[],
   'Berlokasi strategis di kawasan Senayan, mudah dijangkau dari pusat kota. Lapangan indoor dengan lantai anti-slip dan pencahayaan merata di seluruh area bermain.',
   'https://plus.unsplash.com/premium_photo-1768349852671-09bfc8258469?q=80&w=1171&auto=format&fit=crop',
   '{}'::int[], false),
  ('Kelas', 'Kelas Padel Pemula', 'Jakarta Utara', 'Smash Padel Club, PIK', true, 1, 250000, 8, 20,
   array['Parkir','Toilet','AC','Loker']::text[],
   'Kelas dasar untuk yang baru pertama kali main padel. Dipandu pelatih bersertifikat, mulai dari teknik memegang raket, pukulan dasar, sampai aturan main. Sudah termasuk raket dan bola untuk 2 orang.',
   'https://images.unsplash.com/photo-1658491830143-72808ca237e3?q=80&w=1073&auto=format&fit=crop',
   array[2,4,7]::int[], true),
  ('Kelas', 'Kelas Padel Menengah', 'Jakarta Selatan', 'Padel House Kemang', true, 1, 300000, 9, 21,
   array['Parkir','Toilet','AC','Shower','Wifi']::text[],
   'Kelas lanjutan untuk melatih strategi bermain ganda, pukulan smash, dan penggunaan dinding kaca. Cocok untuk pemain yang sudah paham dasar permainan. Sudah termasuk raket dan bola untuk 2 orang.',
   'https://plus.unsplash.com/premium_photo-1755813486079-9997d76a897d?q=80&w=1170&auto=format&fit=crop',
   array[4,7,10,12]::int[], true)
) as v(category, name, city, address, is_indoor, field_count, price_per_hour,
       open_hour, close_hour, facilities, description, image_url,
       class_start_slots, accepting_bookings)
where not exists (select 1 from public.venues x where x.name = v.name);