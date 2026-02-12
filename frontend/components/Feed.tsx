"use client";

import { useEffect, useState } from 'react';
import api from '../lib/api';
import { X, Heart } from 'lucide-react';

interface Photo {
    id: string;
    url: string;
    filename: string;
    createdAt: string;
    favorites: number;
}

export default function Feed({ keyProp }: { keyProp: number }) {
    const [photos, setPhotos] = useState<Photo[]>([]);
    const [selectedPhoto, setSelectedPhoto] = useState<Photo | null>(null);

    useEffect(() => {
        api.get('/photos').then((res) => {
            setPhotos(res.data || []);
        });
    }, [keyProp]);

    const handleFavorite = async (photoId: string) => {
        // Optimistic update
        setPhotos((prev) =>
            prev.map((p) =>
                p.id === photoId ? { ...p, favorites: (p.favorites || 0) + 1 } : p
            )
        );

        try {
            await api.post(`/photos/${photoId}/favorite`);
        } catch (error) {
            console.error('Failed to favorite photo', error);
            // Revert on error
            setPhotos((prev) =>
                prev.map((p) =>
                    p.id === photoId ? { ...p, favorites: (p.favorites || 0) - 1 } : p
                )
            );
        }
    };

    return (
        <>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                {photos.length === 0 && <p className="text-gray-500 col-span-full text-center">No photos yet.</p>}
                {photos.map((photo) => (
                    <div
                        key={photo.id}
                        className="relative group overflow-hidden rounded-lg shadow-md aspect-square bg-gray-200 cursor-pointer"
                        onClick={() => setSelectedPhoto(photo)}
                    >
                        <img
                            src={photo.url}
                            alt={photo.filename}
                            className="object-cover w-full h-full transform transition-transform duration-300 group-hover:scale-110"
                        />
                        <div
                            className="absolute bottom-2 right-2 flex items-center bg-white bg-opacity-75 rounded-full px-2 py-1 shadow-sm hover:bg-opacity-100 transition-all"
                            onClick={(e) => {
                                e.stopPropagation();
                                handleFavorite(photo.id);
                            }}
                        >
                            <Heart size={16} className="text-red-500 mr-1 fill-current" />
                            <span className="text-xs font-semibold text-gray-700">{photo.favorites || 0}</span>
                        </div>
                    </div>
                ))}
            </div>

            {selectedPhoto && (
                <div
                    className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-90 p-4"
                    onClick={() => setSelectedPhoto(null)}
                >
                    <button
                        className="absolute top-4 right-4 text-white hover:text-gray-300 focus:outline-none"
                        onClick={(e) => {
                            e.stopPropagation();
                            setSelectedPhoto(null);
                        }}
                    >
                        <X size={32} />
                    </button>
                    <img
                        src={selectedPhoto.url}
                        alt={selectedPhoto.filename}
                        className="max-w-full max-h-screen object-contain"
                        onClick={(e) => e.stopPropagation()}
                    />
                </div>
            )}
        </>
    );
}
// 